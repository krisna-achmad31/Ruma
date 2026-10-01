import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../../../core/l10n/app_locale.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  late final StreamSubscription<UserEntity?> _authSubscription;

  AuthStatus status = AuthStatus.unknown;
  UserEntity? currentUser;
  bool isSubmitting = false;
  String? errorMessage;

  AuthViewModel({
    required this._authRepository,
    required this._loginUseCase,
    required this._registerUseCase,
  }) {
    // Khusus debug: jalankan dengan --dart-define=DEV_BYPASS_AUTH=true untuk
    // melihat semua layar tanpa login. Tidak aktif di build rilis.
    if (kDebugMode && const bool.fromEnvironment('DEV_BYPASS_AUTH')) {
      currentUser = UserEntity(
        uid: 'uid_dev',
        name: 'Dev',
        email: 'dev@localhost',
        familyId: 'family_demo',
        role: 'admin',
      );
      status = AuthStatus.authenticated;
      _authSubscription = const Stream<UserEntity?>.empty().listen(null);
      return;
    }
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      currentUser = user;
      status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
    });
  }

  Future<bool> login({required String email, required String password}) {
    return _runAuthAction(() => _loginUseCase(email: email, password: password));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final ok = await _runAuthAction(
      () => _registerUseCase(name: name, email: email, phone: phone, password: password),
    );
    if (ok) {
      pendingInvite = true;
      notifyListeners();
    }
    return ok;
  }

  /// Masuk atau daftar lewat Google. Akun baru diarahkan ke layar undang pasangan.
  Future<bool> signInWithGoogle() async {
    bool isNew = false;
    final ok = await _runAuthAction(() async {
      final result = await _authRepository.signInWithGoogle();
      isNew = result.isNew;
      return result.user;
    });
    if (ok && isNew) {
      pendingInvite = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateProfile({String? name, String? phone}) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value(false);
    return _runAuthAction(() => _authRepository.updateProfile(uid: uid, name: name, phone: phone));
  }

  /// True sesudah daftar, supaya pengguna diarahkan ke layar undang pasangan dulu.
  bool pendingInvite = false;

  void finishInvite() {
    pendingInvite = false;
    notifyListeners();
  }

  Future<void> signOut() => _authRepository.signOut();

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordReset(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> findFamilyName(String code) async {
    try {
      return await _authRepository.findFamilyName(code);
    } catch (_) {
      return null;
    }
  }

  Future<bool> joinFamily(String code) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value(false);
    return _runAuthAction(() => _authRepository.joinFamily(uid: uid, inviteCode: code));
  }

  Future<bool> updatePhoto(String dataUri) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value(false);
    return _runAuthAction(() => _authRepository.updatePhoto(uid: uid, photoDataUri: dataUri));
  }

  Future<bool> _runAuthAction(Future<UserEntity> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await action();
      currentUser = user;
      status = AuthStatus.authenticated;
      isSubmitting = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isSubmitting = false;
      errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      isSubmitting = false;
      errorMessage = tr('Terjadi kesalahan, silakan coba lagi.');
      notifyListeners();
      return false;
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return tr('Format email tidak valid.');
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return tr('Email atau password salah.');
      case 'email-already-in-use':
        return tr('Email sudah terdaftar, silakan masuk.');
      case 'weak-password':
        return tr('Password terlalu lemah, minimal 6 karakter.');
      case 'web-context-canceled':
      case 'canceled':
      case 'popup-closed-by-user':
        return tr('Masuk dengan Google dibatalkan.');
      case 'google-not-configured':
      case 'operation-not-allowed':
        return tr('Masuk dengan Google belum diaktifkan.');
      case 'account-exists-with-different-credential':
        return tr('Email ini sudah terdaftar dengan password. Masuk pakai email dulu.');
      case 'network-request-failed':
        return tr('Tidak ada koneksi internet.');
      default:
        return tr('Terjadi kesalahan, silakan coba lagi.');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
