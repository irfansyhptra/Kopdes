import 'package:dio/dio.dart';

// Ambil pesan error yang ramah dari kegagalan HTTP.
// Backend NestJS mengembalikan { statusCode, message, error }.
String extractDioMessage(
  Object error, {
  String fallback = 'Terjadi kesalahan',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.join(', ');
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  return fallback;
}
