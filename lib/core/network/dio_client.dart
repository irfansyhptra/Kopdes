import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/debug/presentation/providers/debug_logger_provider.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final loggerProvider = Provider(
  (ref) => Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final storage = ref.read(secureStorageProvider);
  final logger = ref.read(loggerProvider);

  // 1. Live Request/Response Logger & Debug Screen Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
        final token = await storage.read(key: AppConstants.tokenKey);
        
        final requestStr =
            'METHOD: ${options.method}\n'
            'URL: ${options.uri}\n'
            'HEADERS: ${options.headers}\n'
            'JWT TOKEN: ${token ?? "No Token"}\n'
            'BODY: ${options.data}';
            
        logger.i('--> HTTP REQUEST\n$requestStr');
        ref.read(debugLogProvider.notifier).logRequest(requestStr);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime = response.requestOptions.extra['start_time'] as int?;
        final responseTime = startTime != null
            ? '${DateTime.now().millisecondsSinceEpoch - startTime}ms'
            : 'Unknown';
        final jwtToken = response.requestOptions.headers['Authorization'] ?? 'No Token';
        
        final responseStr =
            'METHOD: ${response.requestOptions.method}\n'
            'URL: ${response.requestOptions.uri}\n'
            'STATUS CODE: ${response.statusCode}\n'
            'RESPONSE TIME: $responseTime\n'
            'JWT TOKEN: $jwtToken\n'
            'RESPONSE BODY: ${response.data}';
            
        logger.i('<-- HTTP RESPONSE\n$responseStr');
        ref.read(debugLogProvider.notifier).logResponse(responseStr);
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        final startTime = error.requestOptions.extra['start_time'] as int?;
        final responseTime = startTime != null
            ? '${DateTime.now().millisecondsSinceEpoch - startTime}ms'
            : 'Unknown';
        final jwtToken = error.requestOptions.headers['Authorization'] ?? 'No Token';
        
        final errorStr =
            'METHOD: ${error.requestOptions.method}\n'
            'URL: ${error.requestOptions.uri}\n'
            'STATUS CODE: ${error.response?.statusCode}\n'
            'RESPONSE TIME: $responseTime\n'
            'JWT TOKEN: $jwtToken\n'
            'ERROR: ${error.message}\n'
            'RESPONSE BODY: ${error.response?.data}';
            
        logger.e('<-- HTTP ERROR\n$errorStr');
        ref.read(debugLogProvider.notifier).logResponse(errorStr);
        return handler.next(error);
      },
    ),
  );

  // 2. Auth Interceptor for adding JWT Token & Handling 401 Refresh Token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // If 401 Unauthorized, attempt token refresh
        if (error.response?.statusCode == 401) {
          final refreshToken = await storage.read(
            key: AppConstants.refreshTokenKey,
          );
          if (refreshToken != null) {
            try {
              logger.d('Access token expired. Attempting token refresh...');
              // Use a separate Dio instance to avoid recursive 401 loops
              final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                final responseMap = response.data as Map<String, dynamic>;
                final dataMap =
                    responseMap['data'] as Map<String, dynamic>? ?? responseMap;

                final newAccessToken = dataMap['accessToken'] as String?;
                final newRefreshToken = dataMap['refreshToken'] as String?;

                if (newAccessToken != null && newRefreshToken != null) {
                  await storage.write(
                    key: AppConstants.tokenKey,
                    value: newAccessToken,
                  );
                  await storage.write(
                    key: AppConstants.refreshTokenKey,
                    value: newRefreshToken,
                  );

                  logger.i(
                    'Token refresh successful. Retrying original request.',
                  );
                  // Retry original request
                  final requestOptions = error.requestOptions;
                  requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final clonedResponse = await dio.fetch(requestOptions);
                  return handler.resolve(clonedResponse);
                }
              }
            } catch (refreshError) {
              logger.e(
                'Refresh token failed, forcing session logout...',
                error: refreshError,
              );
              ref.read(authProvider.notifier).forceSessionExpired();
            }
          } else {
            // No refresh token available, force session expired
            ref.read(authProvider.notifier).forceSessionExpired();
          }
        }
        return handler.next(error);
      },
    ),
  );

  // 3. Automatic Retry Interceptor (Timeout / Connection error)
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      maxRetries: 3,
      retryInterval: const Duration(seconds: 2),
      logger: logger,
    ),
  );

  return dio;
});

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;
  final Logger logger;

  RetryInterceptor({
    required this.dio,
    required this.logger,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final isTimeoutOrNetwork =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    var retryCount = requestOptions.extra['retry_count'] as int? ?? 0;

    if (isTimeoutOrNetwork && retryCount < maxRetries) {
      retryCount++;
      requestOptions.extra['retry_count'] = retryCount;
      logger.w(
        'Network timeout/connection issue. Retrying ($retryCount/$maxRetries) in ${retryInterval.inSeconds}s...',
      );

      await Future.delayed(retryInterval);
      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return onError(e, handler);
        }
        return super.onError(err, handler);
      }
    }
    return super.onError(err, handler);
  }
}
