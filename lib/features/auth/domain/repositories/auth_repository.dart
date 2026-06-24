import '../entities/user.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  });

  Future<void> logout();

  Future<User> getCurrentUser();

  Future<AuthSession> refreshToken({required String refreshToken});

  Future<bool> checkStatus();

  Future<User> updateProfile({required String name, required String phone});
}
