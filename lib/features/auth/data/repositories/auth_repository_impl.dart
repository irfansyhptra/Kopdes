import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );

    // Persist session locally
    await localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await localDataSource.saveUserRole(response.user.role);
    await localDataSource.saveUserCached(response.user);

    return response.toEntity();
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await remoteDataSource.register(
      RegisterRequest(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      ),
    );

    // Persist session locally
    await localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await localDataSource.saveUserRole(response.user.role);
    await localDataSource.saveUserCached(response.user);

    return response.toEntity();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<User> getCurrentUser() async {
    final userModel = await remoteDataSource.getCurrentUser();
    await localDataSource.saveUserCached(userModel);
    return userModel.toEntity();
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) async {
    final response = await remoteDataSource.refreshToken(refreshToken);
    await localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await localDataSource.saveUserRole(response.user.role);
    await localDataSource.saveUserCached(response.user);
    return response.toEntity();
  }

  @override
  Future<bool> checkStatus() async {
    final token = await localDataSource.getAccessToken();
    final user = await localDataSource.getUserCached();
    return token != null && user != null;
  }

  @override
  Future<User> updateProfile({
    required String name,
    required String phone,
  }) async {
    final updatedModel = await remoteDataSource.updateProfile(
      name: name,
      phone: phone,
    );
    await localDataSource.saveUserCached(updatedModel);
    return updatedModel.toEntity();
  }
}
