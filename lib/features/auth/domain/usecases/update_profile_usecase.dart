import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<User> call({required String name, required String phone}) {
    return repository.updateProfile(name: name, phone: phone);
  }
}
