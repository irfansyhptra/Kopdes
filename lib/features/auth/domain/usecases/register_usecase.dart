import '../entities/registration_challenge.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<RegistrationChallenge> call({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
