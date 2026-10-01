import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return repository.registerWithEmail(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
