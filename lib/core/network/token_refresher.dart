import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Penyegaran token gagal karena server tidak terjangkau, bukan karena
/// sesinya ditolak.
///
/// Dibedakan dengan sengaja: kehilangan sinyal bukan alasan mengeluarkan
/// orang dari akunnya. Versi sebelumnya menangkap semua lemparan dan langsung
/// memanggil `forceSessionExpired()`, sehingga membuka aplikasi di tempat
/// tanpa jaringan sama saja dengan ditendang keluar.
class RefreshUnavailable implements Exception {
  final Object cause;
  const RefreshUnavailable(this.cause);

  @override
  String toString() => 'RefreshUnavailable: $cause';
}

/// Menyegarkan access token, satu permintaan pada satu waktu.
///
/// Inilah inti perbaikannya. Backend **merotasi** refresh token: begitu satu
/// permintaan berhasil, token lama dihapus dari basis data. Saat aplikasi
/// dibuka setelah lama ditutup, access token sudah kedaluwarsa dan belasan
/// permintaan beranda berangkat bersamaan — beranda, kategori, keranjang,
/// notifikasi, Kopdes terdekat. Semuanya dijawab 401, dan dulu masing-masing
/// memanggil `/auth/refresh` sendiri dengan refresh token yang sama persis.
///
/// Yang pertama berhasil dan menghapus token itu; sisanya dijawab
/// "Invalid or expired refresh token", lalu yang pertama di antaranya
/// mengakhiri sesi. Itulah "Sesi Anda Telah Berakhir" yang muncul setiap kali
/// aplikasi dibuka setelah beberapa jam.
///
/// Sekarang seluruh pemanggil menunggu satu penyegaran yang sama.
class TokenRefresher {
  final FlutterSecureStorage storage;
  final Dio client;

  /// Penyegaran yang sedang berjalan, dibagi ke semua pemanggil.
  Future<String?>? _inFlight;

  TokenRefresher({required this.storage, required this.client});

  /// Access token baru, atau `null` bila sesinya memang sudah berakhir.
  ///
  /// Melempar [RefreshUnavailable] bila servernya tidak terjangkau.
  Future<String?> refresh() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<String?> _run() async {
    final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
    // Tidak ada refresh token sama sekali: tidak ada sesi untuk disegarkan.
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final Response<dynamic> response;
    try {
      response = await client.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          // Status diperiksa sendiri di bawah supaya 401 bisa dibedakan dari
          // kegagalan jaringan.
          validateStatus: (_) => true,
        ),
      );
    } catch (e) {
      throw RefreshUnavailable(e);
    }

    final status = response.statusCode ?? 0;

    // Ditolak tegas: token sudah dipakai, dicabut, atau kedaluwarsa.
    if (status == 401 || status == 403) return null;

    // Server bermasalah — bukan penolakan. Sesi dipertahankan.
    if (status < 200 || status >= 300) {
      throw RefreshUnavailable('HTTP $status');
    }

    final body = response.data;
    if (body is! Map) throw const RefreshUnavailable('respons tidak terbaca');
    final data = body['data'] as Map? ?? body;

    final accessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;
    if (accessToken == null || newRefreshToken == null) {
      throw const RefreshUnavailable('respons tidak lengkap');
    }

    // Keduanya ditulis sebelum pemanggil mana pun melanjutkan: token lama
    // sudah mati di server begitu respons ini terbentuk.
    await storage.write(key: AppConstants.tokenKey, value: accessToken);
    await storage.write(
      key: AppConstants.refreshTokenKey,
      value: newRefreshToken,
    );
    return accessToken;
  }
}
