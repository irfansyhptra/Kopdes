import '../entities/user.dart';
import '../entities/auth_session.dart';
import '../entities/registration_challenge.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<RegistrationChallenge> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  });

  Future<RegistrationChallenge> resendVerification({required String email});

  Future<void> logout();

  Future<User> getCurrentUser();

  Future<AuthSession> refreshToken({required String refreshToken});

  Future<bool> checkStatus();

  Future<User> updateProfile({required String name, required String phone});
  Future<User> updateAvatar({
    required List<int> bytes,
    required String filename,
  });
}
