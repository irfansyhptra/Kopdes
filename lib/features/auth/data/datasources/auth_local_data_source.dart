import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/login_response.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> saveUserRole(String role);
  Future<void> saveUserCached(UserModel user);

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserRole();
  Future<UserModel?> getUserCached();

  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  @override
  Future<void> saveUserRole(String role) async {
    await secureStorage.write(key: AppConstants.userRoleKey, value: role);
  }

  @override
  Future<void> saveUserCached(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await secureStorage.write(key: 'cached_user_profile', value: userJson);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: AppConstants.tokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<String?> getUserRole() async {
    return await secureStorage.read(key: AppConstants.userRoleKey);
  }

  @override
  Future<UserModel?> getUserCached() async {
    final userJson = await secureStorage.read(key: 'cached_user_profile');
    if (userJson == null) return null;
    try {
      final decodedMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(decodedMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await secureStorage.delete(key: AppConstants.tokenKey);
    await secureStorage.delete(key: AppConstants.refreshTokenKey);
    await secureStorage.delete(key: AppConstants.userRoleKey);
    await secureStorage.delete(key: 'cached_user_profile');
  }
}
