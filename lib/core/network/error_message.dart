import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Mengubah kegagalan jaringan menjadi kalimat yang bisa dibaca orang.
///
/// Dipakai seluruh aplikasi, bukan hanya layar masuk: setiap aksi yang
/// menunggu jaringan melaporkan kegagalannya lewat fungsi yang sama, supaya
/// "tidak ada koneksi" berbunyi sama di keranjang, checkout, dan profil.
///
/// Tanpa ini modal gagal menampilkan `DioException.toString()` — satu
/// paragraf bahasa Inggris berisi status code dan konfigurasi
/// `validateStatus`, yang tidak memberi tahu apa pun tentang apa yang perlu
/// dilakukan pembacanya.
///
/// Pesan dari server dipakai lebih dulu bila ada. Backend sudah menjawab 401
/// dengan "Email atau password salah" dan 409 dengan "Email sudah terdaftar";
/// menuliskan ulang kalimatnya di sini berarti dua tempat yang harus diubah
/// bersamaan, dan yang satu pasti terlupa.
const String _generic = 'Terjadi kesalahan. Coba lagi.';

String networkErrorMessage(Object error) {
  if (error is Failure) return error.message;
  if (error is! DioException) return _generic;

  final status = error.response?.statusCode;
  if (status == null) return _connectionMessage(error.type);

  final fromServer = _serverMessage(error.response?.data);

  return switch (status) {
    400 || 422 => fromServer ?? 'Data yang diisi belum sesuai. Periksa lagi.',
    // Satu kalimat untuk dua sebab, disengaja: server sengaja tidak
    // memberi tahu mana yang salah. Membedakan "email tidak terdaftar" dari
    // "kata sandi salah" membuat siapa pun bisa menebak-nebak alamat untuk
    // mengetahui siapa saja yang punya akun di sini.
    401 => fromServer ?? 'Email tidak terdaftar atau kata sandi salah.',
    403 => fromServer ?? 'Akun ini tidak diizinkan masuk.',
    404 => 'Layanan tidak ditemukan. Coba perbarui aplikasi.',
    409 => fromServer ?? 'Email atau nomor telepon itu sudah terdaftar.',
    429 => 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
    // 503 dipakai backend dengan sengaja dan selalu membawa kalimat yang
    // menyebut langkah berikutnya — mis. pengiriman email OTP sedang mati,
    // yang hanya bisa diselesaikan dengan menghubungi pengurus Kopdes.
    // Menelannya menjadi "Server sedang bermasalah" menyuruh pendaftar
    // menunggu sesuatu yang tidak akan berubah sendiri.
    503 => fromServer ?? 'Layanan sedang tidak tersedia. Coba lagi nanti.',
    // 500/502/504 tidak begitu: isinya "Internal server error" atau halaman
    // HTML dari proksi, yang tidak memberi tahu apa pun.
    >= 500 => 'Server sedang bermasalah. Coba lagi beberapa saat lagi.',
    _ => fromServer ?? _generic,
  };
}

/// Tanpa respons sama sekali: yang gagal adalah sambungannya, bukan isinya.
String _connectionMessage(DioExceptionType type) => switch (type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout =>
    'Server tidak menjawab. Periksa koneksi lalu coba lagi.',
  DioExceptionType.connectionError =>
    'Tidak ada koneksi internet. Periksa jaringan Anda.',
  DioExceptionType.badCertificate =>
    'Sambungan ke server tidak aman. Coba lagi nanti.',
  DioExceptionType.cancel => 'Permintaan dibatalkan.',
  _ => 'Terjadi kesalahan jaringan. Coba lagi.',
};

/// NestJS menjawab `{ statusCode, message, error }`, dan `message` bisa satu
/// kalimat atau daftar kalimat dari class-validator.
String? _serverMessage(Object? data) {
  if (data is! Map) return null;

  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) return message.trim();
  if (message is List) {
    final lines = message
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    if (lines.isNotEmpty) return lines.join('\n');
  }
  return null;
}

/// Pesan error dengan kalimat cadangan pilihan pemanggil.
///
/// Dipertahankan karena tiga layar memakainya. Isinya kini satu jalur dengan
/// [networkErrorMessage]: versi lamanya bisa mengembalikan
/// `DioException.message` apa adanya — berbahasa Inggris dan menyebut
/// `validateStatus` — yang persis masalah yang sedang dibereskan.
String extractDioMessage(
  Object error, {
  String fallback = 'Terjadi kesalahan',
}) {
  final message = networkErrorMessage(error);
  return message == _generic ? fallback : message;
}
