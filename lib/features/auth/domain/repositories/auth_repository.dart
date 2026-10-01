import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity> signInWithEmail({required String email, required String password});

  Future<UserEntity> registerWithEmail({required String name, required String email, required String phone, required String password});

  /// Masuk atau daftar dengan Google. isNew true kalau akun baru dibuat.
  Future<({UserEntity user, bool isNew})> signInWithGoogle();

  Future<UserEntity> updateProfile({required String uid, String? name, String? phone});

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  /// Memindahkan pengguna ke rumah milik kode undangan. Mengembalikan data pengguna terbaru.
  Future<UserEntity> joinFamily({required String uid, required String inviteCode});

  /// Mencari nama rumah dari kode undangan untuk pratinjau sebelum bergabung.
  Future<String?> findFamilyName(String inviteCode);

  Future<UserEntity> updatePhoto({required String uid, required String photoDataUri});
}
