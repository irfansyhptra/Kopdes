import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/login_response.dart';
import '../../domain/entities/registration_challenge.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<RegistrationChallenge> register(RegisterRequest request);
  Future<LoginResponse> verifyEmail({
    required String email,
    required String code,
  });
  Future<RegistrationChallenge> resendVerification(String email);
  Future<UserModel> getCurrentUser();
  Future<LoginResponse> refreshToken(String refreshToken);
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  });
  Future<UserModel> updateAvatar({
    required List<int> bytes,
    required String filename,
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
      throw const ServerFailure('Respons login tidak lengkap dari server.');
    }

    return LoginResponse.fromJson(dataMap);
  }

  @override
  Future<RegistrationChallenge> register(RegisterRequest request) async {
    final response = await dio.post('/auth/register', data: request.toJson());
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;

    if (dataMap['verificationRequired'] != true || dataMap['email'] == null) {
      throw const ServerFailure(
        'Respons registrasi tidak lengkap dari server.',
      );
    }
    return RegistrationChallenge.fromJson(dataMap);
  }

  @override
  Future<LoginResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await dio.post(
      '/auth/verify-email',
      data: {'email': email, 'code': code},
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    if (dataMap['accessToken'] == null ||
        dataMap['refreshToken'] == null ||
        dataMap['user'] == null) {
      throw const ServerFailure(
        'Respons verifikasi tidak lengkap dari server.',
      );
    }
    return LoginResponse.fromJson(dataMap);
  }

  @override
  Future<RegistrationChallenge> resendVerification(String email) async {
    final response = await dio.post(
      '/auth/resend-verification',
      data: {'email': email},
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return RegistrationChallenge.fromJson(dataMap);
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

  @override
  Future<UserModel> updateAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await dio.put(
      '/auth/profile/avatar',
      data: FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return UserModel.fromJson(dataMap);
  }
}
