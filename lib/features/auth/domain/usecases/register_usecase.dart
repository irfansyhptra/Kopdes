import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthSession> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) {
    return repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
  }
}
