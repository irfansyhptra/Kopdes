import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

enum HealthState { checking, healthy, unhealthy }

/// Klien khusus untuk probe kesehatan.
///
/// Sengaja terpisah dari [dioProvider]: probe ini berjalan sebelum sesi ada dan
/// tidak boleh ikut antre di balik interceptor auth/retry aplikasi. Yang lebih
/// penting, batas waktunya harus jauh lebih pendek — probe ini menahan splash,
/// jadi gagal cepat lebih berguna daripada menunggu lama.
///
/// Satu instance dipakai berulang supaya koneksi HTTP-nya bisa dipakai lagi;
/// versi sebelumnya membuat `Dio()` baru pada setiap percobaan.
final healthDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      // Koneksi ke edge harus cepat walau fungsi serverless-nya masih dingin.
      connectTimeout: const Duration(seconds: 5),
      // Responsnya yang boleh lambat: cold start Vercel perlu waktu bangun.
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((
  ref,
) {
  return HealthNotifier(ref.watch(healthDioProvider));
});

class HealthNotifier extends StateNotifier<HealthState> {
  final Dio _dio;

  HealthNotifier(this._dio) : super(HealthState.checking);

  /// Sekali percobaan, berbatas waktu tegas.
  ///
  /// Versi sebelumnya mencoba 3× dengan timeout 10 detik ditambah jeda 1 detik
  /// — total sampai ~32 detik menahan splash sebelum tombol coba-lagi muncul.
  /// Percobaan berulang di sini tidak menambah apa pun: kalau backend belum
  /// siap dalam 10 detik, aplikasi tetap masuk dalam mode terdegradasi dan
  /// layar tujuan menampilkan keadaan gagal pada datanya sendiri.
  Future<bool> checkServerHealth() async {
    state = HealthState.checking;
    try {
      // Liveness hanya memastikan fungsi API dapat menjawab. Readiness boleh
      // gagal karena layanan tambahan sedang terganggu dan tidak boleh
      // mengunci seluruh aplikasi di splash.
      final response = await _dio.get<dynamic>('/health/live');
      final healthy = response.statusCode == 200;
      state = healthy ? HealthState.healthy : HealthState.unhealthy;
      return healthy;
    } catch (e) {
      if (kDebugMode) debugPrint('Health check gagal: $e');
      state = HealthState.unhealthy;
      return false;
    }
  }
}
