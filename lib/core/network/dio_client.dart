import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math';

import '../config/api_config.dart';
import '../config/env_config.dart';
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
        // Minta respons terkompresi. Katalog produk JSON menyusut ±70–80%;
        // di jaringan desa yang lambat itu selisih detik, bukan milidetik.
        'Accept-Encoding': 'gzip, deflate',
      },
    ),
  );

  final storage = ref.read(secureStorageProvider);
  final logger = ref.read(loggerProvider);

  // 1. Logger permintaan/respons.
  //
  // Hanya dipasang saat EnvConfig.enableLogging aktif. Versi sebelumnya
  // dipasang di semua build: setiap panggilan merangkai string berisi seluruh
  // body permintaan DAN respons — biaya CPU + alokasi memori di jalur terpanas
  // aplikasi — dan mencetak JWT mentah ke log perangkat.
  if (EnvConfig.enableLogging) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
          final requestStr =
              'METHOD: ${options.method}\n'
              'URL: ${options.uri}\n'
              'BODY: ${options.data}';
          logger.i('--> HTTP REQUEST\n$requestStr');
          ref.read(debugLogProvider.notifier).logRequest(requestStr);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final responseStr =
              'METHOD: ${response.requestOptions.method}\n'
              'URL: ${response.requestOptions.uri}\n'
              'STATUS CODE: ${response.statusCode}\n'
              'RESPONSE TIME: ${_elapsed(response.requestOptions)}\n'
              'RESPONSE BODY: ${response.data}';
          logger.i('<-- HTTP RESPONSE\n$responseStr');
          ref.read(debugLogProvider.notifier).logResponse(responseStr);
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final errorStr =
              'METHOD: ${error.requestOptions.method}\n'
              'URL: ${error.requestOptions.uri}\n'
              'STATUS CODE: ${error.response?.statusCode}\n'
              'RESPONSE TIME: ${_elapsed(error.requestOptions)}\n'
              'ERROR: ${error.message}\n'
              'RESPONSE BODY: ${error.response?.data}';
          logger.e('<-- HTTP ERROR\n$errorStr');
          ref.read(debugLogProvider.notifier).logResponse(errorStr);
          return handler.next(error);
        },
      ),
    );
  }

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

  // 3. Dedup permintaan GET yang identik & sedang berjalan.
  dio.interceptors.add(InFlightDedupeInterceptor());

  // 4. Retry otomatis untuk kegagalan jaringan.
  dio.interceptors.add(RetryInterceptor(dio: dio, logger: logger));

  return dio;
});

const String _startTimeKey = 'start_time';

/// Tandai satu permintaan non-idempoten sebagai aman untuk diulang — hanya
/// bila endpoint-nya idempoten di sisi server (mis. memakai idempotency key).
Options retryable() => Options(extra: const {RetryInterceptor.optInKey: true});

String _elapsed(RequestOptions options) {
  final start = options.extra[_startTimeKey] as int?;
  if (start == null) return 'Unknown';
  return '${DateTime.now().millisecondsSinceEpoch - start}ms';
}

/// Menggabungkan permintaan GET identik yang sedang berjalan menjadi satu.
///
/// Beranda dan Marketplace sama-sama meminta `/categories`, dan tiap pindah tab
/// bisa memicu keduanya nyaris bersamaan. Tanpa ini, tiap pemanggil membuka
/// koneksinya sendiri untuk jawaban yang persis sama.
///
/// Hanya GET: menggabungkan POST akan membuat dua pemanggil berbagi satu efek
/// samping, yang bukan hal yang sama sekali.
class InFlightDedupeInterceptor extends Interceptor {
  final Map<String, Future<Response<dynamic>>> _inFlight = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = options.uri.toString();
    final running = _inFlight[key];
    if (running != null) {
      running.then(
        (res) => handler.resolve(
          Response(
            requestOptions: options,
            data: res.data,
            statusCode: res.statusCode,
            headers: res.headers,
          ),
        ),
        onError: (Object e) => handler.reject(
          e is DioException
              ? e
              : DioException(requestOptions: options, error: e),
        ),
      );
      return;
    }

    final completer = Completer<Response<dynamic>>();
    _inFlight[key] = completer.future;
    options.extra[_dedupeKey] = key;
    options.extra[_dedupeCompleter] = completer;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _settle(response.requestOptions, (c) => c.complete(response));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _settle(err.requestOptions, (c) => c.completeError(err));
    handler.next(err);
  }

  void _settle(
    RequestOptions options,
    void Function(Completer<Response<dynamic>>) finish,
  ) {
    final key = options.extra.remove(_dedupeKey) as String?;
    final completer =
        options.extra.remove(_dedupeCompleter) as Completer<Response<dynamic>>?;
    if (key != null) _inFlight.remove(key);
    if (completer != null && !completer.isCompleted) finish(completer);
  }

  static const String _dedupeKey = 'dedupe_key';
  static const String _dedupeCompleter = 'dedupe_completer';
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final Logger logger;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    required this.logger,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  /// Taruh `true` di `options.extra` untuk mengizinkan retry pada metode
  /// non-idempoten. Lihat [retryable].
  static const String optInKey = 'allow_retry';
  static const String _countKey = 'retry_count';

  static final _random = Random();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    if (!_isTransient(err) || !_isSafeToRetry(options)) {
      return handler.next(err);
    }

    final attempt = (options.extra[_countKey] as int? ?? 0) + 1;
    if (attempt > maxRetries) return handler.next(err);
    options.extra[_countKey] = attempt;

    // Backoff eksponensial + jitter. Jeda tetap 2 detik seperti sebelumnya
    // berarti pengguna menunggu 6 detik penuh sebelum melihat error, dan
    // semua klien yang gagal bersamaan akan mencoba lagi pada detik yang sama.
    final backoff = baseDelay * pow(2, attempt - 1).toDouble();
    final jitter = Duration(milliseconds: _random.nextInt(250));
    final wait = backoff + jitter;

    logger.w(
      'Jaringan bermasalah (${err.type.name}). '
      'Mencoba lagi $attempt/$maxRetries dalam ${wait.inMilliseconds}ms — '
      '${options.method} ${options.path}',
    );
    await Future<void>.delayed(wait);

    try {
      // fetch() masuk kembali ke rantai interceptor; retry_count ikut terbawa
      // di extra, jadi percobaan berikutnya terhitung dengan benar dan
      // berhenti sendiri di batas maxRetries.
      return handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // 502/503/504 = server sedang tidak sehat, bukan permintaan yang salah.
        final code = err.response?.statusCode ?? 0;
        return code == 502 || code == 503 || code == 504;
      default:
        return false;
    }
  }

  /// Hanya metode idempoten yang diulang secara diam-diam.
  ///
  /// Timeout TIDAK berarti server tidak menerima permintaan — bisa saja pesanan
  /// sudah dibuat dan hanya responsnya yang tidak sampai. Mengulang POST
  /// /orders dalam keadaan itu membuat pesanan ganda; pengguna membayar dua
  /// kali. Endpoint non-idempoten harus meminta izin lewat [retryable].
  bool _isSafeToRetry(RequestOptions options) {
    if (options.extra[optInKey] == true) return true;
    const idempotent = {'GET', 'HEAD', 'OPTIONS'};
    return idempotent.contains(options.method.toUpperCase());
  }
}
