import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({fb_auth.FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      // Saat daftar baru (email atau Google), dokumen pengguna dibuat sesaat
      // setelah akun Auth jadi. Tunggu sebentar supaya status tidak salah dibaca keluar.
      try {
        for (int i = 0; i < 8; i++) {
          final doc = await _fetchUserDoc(user.uid);
          if (doc != null) return doc;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      } on FirebaseException {
        // Dokumen tidak bisa dibaca (aturan Firestore menolak). Anggap belum masuk
        // supaya aplikasi tidak tertahan di splash.
      }
      return null;
    });
  }

  Future<UserModel> signInWithEmail({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final userModel = await _fetchUserDoc(credential.user!.uid);
    if (userModel == null) {
      throw StateError('Data pengguna tidak ditemukan di Firestore.');
    }
    return userModel;
  }

  Future<UserModel> registerWithEmail({required String name, required String email, required String phone, required String password}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final familyRef = _firestore.collection('families').doc();
    await familyRef.set({
      'name': 'Keluarga $name',
      'location': '',
      'members': [uid],
      'inviteCode': _newInviteCode(),
      'createdAt': DateTime.now().toIso8601String(),
    });

    final userModel = UserModel(uid: uid, name: name, email: email, phone: phone, familyId: familyRef.id, role: 'admin');
    await _firestore.collection('users').doc(uid).set(userModel.toMap());
    return userModel;
  }

  /// Masuk dengan Google. Akun baru langsung dibuatkan rumah dan data pengguna.
  /// Mengembalikan pengguna dan penanda apakah akun ini baru.
  Future<(UserModel, bool)> signInWithGoogle() async {
    // Pakai pemilih akun native Android (Credential Manager), bukan alur browser,
    // karena alur browser gagal di sebagian HP ("missing initial state").
    final String? idToken;
    String? googleName;
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize();
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      idToken = account.authentication.idToken;
      googleName = account.displayName;
    } on GoogleSignInException catch (e) {
      throw fb_auth.FirebaseAuthException(
        code: e.code == GoogleSignInExceptionCode.canceled ? 'canceled' : 'google-not-configured',
        message: e.description,
      );
    }
    if (idToken == null) {
      throw fb_auth.FirebaseAuthException(code: 'google-not-configured');
    }
    final credential = await _firebaseAuth.signInWithCredential(fb_auth.GoogleAuthProvider.credential(idToken: idToken));
    final user = credential.user!;
    final existing = await _fetchUserDoc(user.uid);
    if (existing != null) {
      // Akun lama yang namanya masih dari awalan email diganti dengan nama akun Google.
      final emailPrefix = (user.email ?? '').split('@').first;
      final gName = (googleName ?? '').trim();
      if (gName.isNotEmpty && existing.name == emailPrefix) {
        return (await updateProfile(uid: user.uid, name: gName), false);
      }
      return (existing, false);
    }

    // Nama dari akun Google lebih dulu, baru dari profil Firebase, terakhir dari email.
    final name = [googleName, user.displayName].map((n) => (n ?? '').trim()).firstWhere((n) => n.isNotEmpty, orElse: () => (user.email ?? 'Kamu').split('@').first);
    final familyRef = _firestore.collection('families').doc();
    await familyRef.set({
      'name': 'Keluarga ${name.split(' ').first}',
      'location': '',
      'members': [user.uid],
      'inviteCode': _newInviteCode(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    final model = UserModel(
      uid: user.uid,
      name: name,
      email: user.email ?? '',
      phone: user.phoneNumber,
      familyId: familyRef.id,
      role: 'admin',
      photoUrl: user.photoURL,
    );
    await _firestore.collection('users').doc(user.uid).set(model.toMap());
    return (model, true);
  }

  Future<UserModel> updateProfile({required String uid, String? name, String? phone}) async {
    await _firestore.collection('users').doc(uid).update({'name': ?name, 'phone': ?phone});
    return (await _fetchUserDoc(uid))!;
  }

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

  static bool _googleReady = false;

  Future<void> sendPasswordReset(String email) => _firebaseAuth.sendPasswordResetEmail(email: email);

  Future<String?> findFamilyName(String inviteCode) async {
    final snap = await _firestore.collection('families').where('inviteCode', isEqualTo: inviteCode.toUpperCase()).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return (snap.docs.first.data()['name'] as String?) ?? '';
  }

  Future<UserModel> joinFamily({required String uid, required String inviteCode}) async {
    final snap = await _firestore.collection('families').where('inviteCode', isEqualTo: inviteCode.toUpperCase()).limit(1).get();
    if (snap.docs.isEmpty) {
      throw StateError('Kode rumah tidak ditemukan.');
    }
    final familyRef = snap.docs.first.reference;
    await familyRef.update({'members': FieldValue.arrayUnion([uid])});
    await _firestore.collection('users').doc(uid).update({'familyId': familyRef.id, 'role': 'member'});
    return (await _fetchUserDoc(uid))!;
  }

  Future<UserModel> updatePhoto({required String uid, required String photoDataUri}) async {
    await _firestore.collection('users').doc(uid).update({'photoUrl': photoDataUri});
    return (await _fetchUserDoc(uid))!;
  }

  Future<UserModel?> _fetchUserDoc(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) return null;
    return UserModel.fromMap(uid, snapshot.data()!);
  }

  /// Kode 6 karakter tanpa huruf yang mirip angka (O, I, 0, 1).
  static String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
