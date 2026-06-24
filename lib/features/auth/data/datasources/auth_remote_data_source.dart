import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> register(RegisterRequest request);
  Future<UserModel> getCurrentUser();
  Future<LoginResponse> refreshToken(String refreshToken);
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await dio.post('/auth/login', data: request.toJson());
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;

    // Strict validation: fail login if any expected field is missing
    if (dataMap['accessToken'] == null ||
        dataMap['refreshToken'] == null ||
        dataMap['user'] == null) {
      throw Exception('Respons login tidak lengkap dari server');
    }

    return LoginResponse.fromJson(dataMap);
  }

  @override
  Future<LoginResponse> register(RegisterRequest request) async {
    final response = await dio.post('/auth/register', data: request.toJson());
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;

    if (dataMap['accessToken'] == null ||
        dataMap['refreshToken'] == null ||
        dataMap['user'] == null) {
      throw Exception('Respons registrasi tidak lengkap dari server');
    }

    return LoginResponse.fromJson(dataMap);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await dio.get('/auth/me');
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return UserModel.fromJson(dataMap);
  }

  @override
  Future<LoginResponse> refreshToken(String refreshToken) async {
    final response = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return LoginResponse.fromJson(dataMap);
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await dio.put(
      '/auth/profile',
      data: {'name': name, 'phone': phone},
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return UserModel.fromJson(dataMap);
  }
}
