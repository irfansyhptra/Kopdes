import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/error/failures.dart';
import 'package:kopdes/core/network/dio_client.dart';
import 'package:kopdes/core/network/error_message.dart';

DioException _response(int status, Object? body) {
  final options = RequestOptions(path: '/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  group('networkErrorMessage', () {
    // Inilah keluhannya: modal gagal menampilkan DioException.toString(),
    // satu paragraf bahasa Inggris tentang validateStatus.
    test('tidak pernah mengembalikan DioException.toString()', () {
      final raw = _response(401, null).toString();
      expect(raw, contains('DioException'));
      expect(networkErrorMessage(_response(401, null)), isNot(contains('Dio')));
    });

    test('401 tanpa badan respons menyebut kata sandi', () {
      expect(
        networkErrorMessage(_response(401, null)),
        'Email tidak terdaftar atau kata sandi salah.',
      );
    });

    test('pesan server dipakai apa adanya', () {
      expect(
        networkErrorMessage(
          _response(401, {'message': 'Email atau password salah'}),
        ),
        'Email atau password salah',
      );
    });

    test('daftar pesan class-validator digabung per baris', () {
      expect(
        networkErrorMessage(
          _response(400, {
            'message': ['Email tidak valid', 'Password minimal 8 karakter'],
          }),
        ),
        'Email tidak valid\nPassword minimal 8 karakter',
      );
    });

    test('409 menjelaskan akun yang sudah ada', () {
      expect(
        networkErrorMessage(_response(409, null)),
        contains('sudah terdaftar'),
      );
    });

    test('5xx tidak menyalahkan penggunanya', () {
      final message = networkErrorMessage(_response(500, null));
      expect(message, contains('Server'));
      expect(message, isNot(contains('kata sandi')));
    });

    test('503 menyampaikan alasan server, bukan "Server bermasalah"', () {
      // Pendaftaran gagal karena kode OTP tidak bisa dikirim: seluruh server
      // sehat, dan satu-satunya langkah yang menolong ada di kalimat server.
      // Menelannya menjadi kalimat umum menyuruh pendaftar menunggu sesuatu
      // yang tidak akan berubah sendiri.
      final message = networkErrorMessage(
        _response(503, {
          'statusCode': 503,
          'message':
              'Kode verifikasi tidak bisa dikirim ke email Anda. Pengiriman '
              'email sedang tidak tersedia — coba lagi beberapa menit lagi, '
              'atau hubungi pengurus Kopdes desa Anda untuk didaftarkan.',
        }),
      );
      expect(message, contains('hubungi pengurus Kopdes'));
      expect(message, isNot(contains('Server sedang bermasalah')));
    });

    test('503 tanpa kalimat server tetap jujur tentang layanannya', () {
      expect(
        networkErrorMessage(_response(503, null)),
        contains('tidak tersedia'),
      );
    });

    test('500 tetap umum: isinya hanya "Internal server error"', () {
      expect(
        networkErrorMessage(
          _response(500, {
            'statusCode': 500,
            'message': 'Internal server error',
          }),
        ),
        contains('Server sedang bermasalah'),
      );
    });

    test('tanpa respons: yang gagal sambungannya', () {
      final offline = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      );
      expect(networkErrorMessage(offline), contains('koneksi'));
    });

    test('Failure milik proyek tampil apa adanya', () {
      expect(
        networkErrorMessage(
          const ServerFailure('Respons login tidak lengkap.'),
        ),
        'Respons login tidak lengkap.',
      );
    });

    test('error tak dikenal tetap jadi kalimat, bukan jejak tipe', () {
      expect(networkErrorMessage(StateError('boom')), isNot(contains('boom')));
    });
  });

  group('isCredentialAttempt', () {
    // Salah ketik kata sandi bukan sesi kedaluwarsa. Tanpa pembedaan ini,
    // 401 dari login memanggil forceSessionExpired(): sesi terhapus, router
    // berpindah halaman, dan dialog gagalnya ikut tertutup.
    test('endpoint kredensial dikecualikan dari alur sesi kedaluwarsa', () {
      expect(isCredentialAttempt('/auth/login'), isTrue);
      expect(isCredentialAttempt('/auth/register'), isTrue);
      expect(isCredentialAttempt('/auth/refresh'), isTrue);
    });

    test('endpoint ber-sesi tetap memicu penyegaran token', () {
      expect(isCredentialAttempt('/auth/me'), isFalse);
      expect(isCredentialAttempt('/orders'), isFalse);
      expect(isCredentialAttempt('/koperasi'), isFalse);
    });
  });
}
