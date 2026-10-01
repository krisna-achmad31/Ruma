import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Stream<UserEntity?> get authStateChanges => _remote.authStateChanges;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) =>
      _remote.signInWithEmail(email: email, password: password);

  @override
  Future<UserEntity> registerWithEmail({required String name, required String email, required String phone, required String password}) =>
      _remote.registerWithEmail(name: name, email: email, phone: phone, password: password);

  @override
  Future<({UserEntity user, bool isNew})> signInWithGoogle() async {
    final (user, isNew) = await _remote.signInWithGoogle();
    return (user: user as UserEntity, isNew: isNew);
  }

  @override
  Future<UserEntity> updateProfile({required String uid, String? name, String? phone}) => _remote.updateProfile(uid: uid, name: name, phone: phone);

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendPasswordReset(String email) => _remote.sendPasswordReset(email);

  @override
  Future<UserEntity> joinFamily({required String uid, required String inviteCode}) => _remote.joinFamily(uid: uid, inviteCode: inviteCode);

  @override
  Future<String?> findFamilyName(String inviteCode) => _remote.findFamilyName(inviteCode);

  @override
  Future<UserEntity> updatePhoto({required String uid, required String photoDataUri}) => _remote.updatePhoto(uid: uid, photoDataUri: photoDataUri);
}
