import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/constants/app_constants.dart';
import 'package:kopdes/core/network/token_refresher.dart';

/// Penyimpanan aman di memori.
class _MemoryStorage extends FlutterSecureStorage {
  final Map<String, String> values;
  _MemoryStorage(this.values);

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// Meniru backend yang MEROTASI refresh token: begitu satu permintaan
/// berhasil, token lama mati. Inilah perilaku yang membuat penyegaran
/// paralel merusak sesi.
class _RotatingAdapter implements HttpClientAdapter {
  String validToken;
  int calls = 0;
  int issued = 0;
  final Completer<void>? gate;

  _RotatingAdapter({required this.validToken, this.gate});

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    calls++;
    if (gate != null) await gate!.future;

    final body = options.data;
    final sent =
        (body is String ? jsonDecode(body) as Map : body as Map)['refreshToken']
            as String;
    if (sent != validToken) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Invalid or expired refresh token'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    issued++;
    validToken = 'refresh-$issued';
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'accessToken': 'access-$issued', 'refreshToken': validToken},
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

({TokenRefresher refresher, _MemoryStorage storage, _RotatingAdapter adapter})
_harness({Completer<void>? gate, String stored = 'refresh-0'}) {
  final adapter = _RotatingAdapter(validToken: 'refresh-0', gate: gate);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;

  final storage = _MemoryStorage({
    AppConstants.tokenKey: 'access-0',
    AppConstants.refreshTokenKey: stored,
  });

  return (
    refresher: TokenRefresher(storage: storage, client: dio),
    storage: storage,
    adapter: adapter,
  );
}

void main() {
  group('TokenRefresher', () {
    test('menyegarkan dan menyimpan kedua token baru', () async {
      final h = _harness();
      final token = await h.refresher.refresh();

      expect(token, 'access-1');
      expect(h.storage.values[AppConstants.tokenKey], 'access-1');
      expect(h.storage.values[AppConstants.refreshTokenKey], 'refresh-1');
    });

    // INILAH bugnya. Membuka aplikasi setelah lama ditutup membuat belasan
    // permintaan berangkat bersamaan, semuanya dijawab 401. Dulu masing-
    // masing menyegarkan sendiri: yang pertama merotasi token, sisanya
    // ditolak, dan sesinya diakhiri.
    test('sepuluh pemanggil bersamaan hanya memicu SATU penyegaran', () async {
      final gate = Completer<void>();
      final h = _harness(gate: gate);

      final results = Future.wait([
        for (var i = 0; i < 10; i++) h.refresher.refresh(),
      ]);
      gate.complete();

      final tokens = await results;
      expect(h.adapter.calls, 1, reason: 'hanya satu panggilan /auth/refresh');
      expect(h.adapter.issued, 1);
      // Semuanya menerima token yang sama, dan tidak ada yang kebagian null.
      expect(tokens, everyElement('access-1'));
    });

    test('penyegaran berikutnya memakai token hasil rotasi', () async {
      final h = _harness();
      await h.refresher.refresh();
      final second = await h.refresher.refresh();

      expect(second, 'access-2');
      expect(h.adapter.calls, 2);
    });

    test('ditolak 401: null, artinya sesi memang berakhir', () async {
      final h = _harness(stored: 'refresh-sudah-dicabut');
      expect(await h.refresher.refresh(), isNull);
    });

    test(
      'tanpa refresh token tersimpan: null tanpa menyentuh jaringan',
      () async {
        final h = _harness();
        await h.storage.write(key: AppConstants.refreshTokenKey, value: null);

        expect(await h.refresher.refresh(), isNull);
        expect(h.adapter.calls, 0);
      },
    );

    // Kehilangan sinyal bukan alasan mengeluarkan orang dari akunnya.
    test('jaringan mati melempar RefreshUnavailable, bukan null', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _FailingAdapter();
      final refresher = TokenRefresher(
        storage: _MemoryStorage({AppConstants.refreshTokenKey: 'refresh-0'}),
        client: dio,
      );

      await expectLater(
        refresher.refresh(),
        throwsA(isA<RefreshUnavailable>()),
      );
    });

    test('server 500 juga tidak mengakhiri sesi', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _StatusAdapter(503);
      final refresher = TokenRefresher(
        storage: _MemoryStorage({AppConstants.refreshTokenKey: 'refresh-0'}),
        client: dio,
      );

      await expectLater(
        refresher.refresh(),
        throwsA(isA<RefreshUnavailable>()),
      );
    });

    test('kegagalan tidak mengunci penyegar untuk selamanya', () async {
      final h = _harness(stored: 'refresh-salah');
      expect(await h.refresher.refresh(), isNull);

      // Penyegaran berikutnya tetap berjalan — slot in-flight sudah dilepas.
      await h.storage.write(
        key: AppConstants.refreshTokenKey,
        value: 'refresh-0',
      );
      expect(await h.refresher.refresh(), 'access-1');
    });
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) =>
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );

  @override
  void close({bool force = false}) {}
}

class _StatusAdapter implements HttpClientAdapter {
  final int status;
  _StatusAdapter(this.status);

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async =>
      ResponseBody.fromString(
        '{}',
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
