import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/koperasi/data/koperasi_remote_data_source.dart';
import 'package:kopdes/features/koperasi/presentation/providers/koperasi_provider.dart';

/// Merekam permintaan terakhir dan menjawabnya dengan daftar kosong.
///
/// Yang diuji di sini adalah *permintaannya*, bukan jawabannya: bug yang
/// diperbaiki adalah daftar Kopdes/UMKM yang menyusut karena radius bawaan,
/// dan itu terlihat dari path serta query yang dikirim.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'koperasi': const [],
          'umkm': const [],
          'total': 0,
          'page': 1,
          'limit': 10,
          'totalPages': 1,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({KoperasiRemoteDataSource remote, _RecordingAdapter adapter}) _source() {
  final adapter = _RecordingAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;
  return (remote: KoperasiRemoteDataSource(dio), adapter: adapter);
}

void main() {
  group('daftar Kopdes & Mitra', () {
    test('tanpa koordinat: daftar lengkap, bukan endpoint radius', () async {
      final s = _source();
      await s.remote.fetchKoperasiList();

      expect(s.adapter.last!.path, '/koperasi');
      expect(s.adapter.last!.queryParameters.containsKey('latitude'), isFalse);
      expect(s.adapter.last!.queryParameters.containsKey('radius'), isFalse);
    });

    test(
      'dengan koordinat: tetap /koperasi, koordinat hanya mengurutkan',
      () async {
        final s = _source();
        await s.remote.fetchKoperasiList(latitude: 5.1, longitude: 97.2);

        expect(s.adapter.last!.path, '/koperasi');
        expect(s.adapter.last!.queryParameters['latitude'], 5.1);
        expect(s.adapter.last!.queryParameters['longitude'], 97.2);
        // Tidak ada radius: inilah bedanya dengan /koperasi/nearby, yang
        // memotong apa pun di luarnya.
        expect(s.adapter.last!.queryParameters.containsKey('radius'), isFalse);
      },
    );

    test('pencarian diteruskan ke server, bukan disaring di layar', () async {
      final s = _source();
      await s.remote.fetchKoperasiList(search: 'Blang');
      expect(s.adapter.last!.queryParameters['search'], 'Blang');

      await s.remote.fetchMitraList(search: 'Kopi');
      expect(s.adapter.last!.path, '/umkm');
      expect(s.adapter.last!.queryParameters['search'], 'Kopi');
    });

    test('mitra tanpa koordinat tetap memanggil daftar lengkap', () async {
      final s = _source();
      await s.remote.fetchMitraList();

      expect(s.adapter.last!.path, '/umkm');
      expect(s.adapter.last!.queryParameters.containsKey('radius'), isFalse);
    });
  });

  group('filter jarak', () {
    // Nilai bawaan 10 km inilah bug aslinya: Kopdes di kabupaten yang
    // desanya berjauhan tidak pernah muncul meski terdaftar.
    test('bawaannya tanpa batas jarak', () {
      expect(const KoperasiFilter().radiusKm, isNull);
      expect(const MitraFilter().radiusKm, isNull);
    });

    test('radius bisa dipilih lalu dilepas lagi', () {
      final narrowed = const KoperasiFilter().copyWith(radiusKm: 5);
      expect(narrowed.radiusKm, 5);
      expect(narrowed.copyWith(clearRadius: true).radiusKm, isNull);

      final mitra = const MitraFilter().copyWith(radiusKm: 25);
      expect(mitra.radiusKm, 25);
      expect(mitra.copyWith(clearRadius: true).radiusKm, isNull);
    });

    test('melepas radius tidak ikut menghapus filter lain', () {
      final f = const KoperasiFilter()
          .copyWith(search: 'Blang', minRating: 4, radiusKm: 10)
          .copyWith(clearRadius: true);

      expect(f.radiusKm, isNull);
      expect(f.search, 'Blang');
      expect(f.minRating, 4);
    });
  });
}
