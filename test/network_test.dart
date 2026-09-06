import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:kopdes/core/network/dio_client.dart';
import 'package:kopdes/core/network/health_provider.dart';
import 'package:kopdes/core/network/paginated.dart';

/// Adapter yang selalu gagal seperti koneksi putus, sambil menghitung
/// berapa kali tiap metode benar-benar dikirim ke jaringan.
class _FailingAdapter implements HttpClientAdapter {
  final Map<String, int> attempts = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) {
    attempts.update(options.method, (v) => v + 1, ifAbsent: () => 1);
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithRetry(_FailingAdapter adapter, {int maxRetries = 2}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logger: Logger(level: Level.off),
      maxRetries: maxRetries,
      baseDelay: const Duration(milliseconds: 1),
    ),
  );
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test('mengulang GET sampai batas maxRetries', () async {
      final adapter = _FailingAdapter();
      final dio = _dioWithRetry(adapter);

      await expectLater(dio.get('/products'), throwsA(isA<DioException>()));

      // 1 percobaan awal + 2 pengulangan.
      expect(adapter.attempts['GET'], 3);
    });

    // Timeout tidak berarti server menolak permintaan. Kalau POST /orders
    // diulang diam-diam, pesanan bisa terbuat dua kali dan pengguna membayar
    // dua kali. Ini penjaga terpenting di berkas ini.
    test('TIDAK mengulang POST', () async {
      final adapter = _FailingAdapter();
      final dio = _dioWithRetry(adapter);

      await expectLater(
        dio.post('/orders', data: const {'x': 1}),
        throwsA(isA<DioException>()),
      );

      expect(adapter.attempts['POST'], 1);
    });

    test('mengulang POST hanya bila diminta lewat retryable()', () async {
      final adapter = _FailingAdapter();
      final dio = _dioWithRetry(adapter);

      await expectLater(
        dio.post('/orders', data: const {'x': 1}, options: retryable()),
        throwsA(isA<DioException>()),
      );

      expect(adapter.attempts['POST'], 3);
    });

    test('DELETE juga tidak diulang tanpa izin', () async {
      final adapter = _FailingAdapter();
      final dio = _dioWithRetry(adapter);

      await expectLater(
        dio.delete('/products/1'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.attempts['DELETE'], 1);
    });
  });

  _healthTests();

  group('Paginated', () {
    Map<String, dynamic> item(String id) => {'id': id};

    test('membaca meta dan tahu masih ada halaman berikutnya', () {
      final page = Paginated.fromJson(
        {
          'products': [item('a'), item('b')],
          'meta': {'total': 40, 'page': 1, 'limit': 20, 'totalPages': 2},
        },
        'products',
        (j) => j['id'] as String,
      );

      expect(page.items, ['a', 'b']);
      expect(page.page, 1);
      expect(page.total, 40);
      expect(page.hasMore, isTrue);
    });

    test('halaman terakhir tidak meminta lagi', () {
      final page = Paginated.fromJson(
        {
          'products': [item('z')],
          'meta': {'total': 21, 'page': 2, 'limit': 20, 'totalPages': 2},
        },
        'products',
        (j) => j['id'] as String,
      );

      expect(page.hasMore, isFalse);
    });

    // Tanpa meta, lebih baik berhenti daripada meminta halaman yang tidak ada
    // tanpa henti sambil terus menembak jaringan.
    test('tanpa meta dianggap satu-satunya halaman', () {
      final page = Paginated.fromJson(
        {
          'products': [item('a')],
        },
        'products',
        (j) => j['id'] as String,
      );

      expect(page.hasMore, isFalse);
      expect(page.total, 1);
    });

    test('payload kosong atau bentuk tak terduga tidak melempar', () {
      final empty = Paginated.fromJson(
        const {},
        'products',
        (j) => j['id'] as String,
      );
      expect(empty.items, isEmpty);
      expect(empty.hasMore, isFalse);

      final junk = Paginated.fromJson(
        'bukan map',
        'products',
        (j) => j['id'] as String,
      );
      expect(junk.items, isEmpty);
    });

    test('append menyambung halaman dan memakai meta terbaru', () {
      final first = Paginated<String>(
        items: const ['a'],
        page: 1,
        totalPages: 2,
        total: 2,
      );
      final second = Paginated<String>(
        items: const ['b'],
        page: 2,
        totalPages: 2,
        total: 2,
      );

      final merged = first.append(second);
      expect(merged.items, ['a', 'b']);
      expect(merged.page, 2);
      expect(merged.hasMore, isFalse);
    });
  });
}

// ── Health probe ────────────────────────────────────────────────────────────

class _StubAdapter implements HttpClientAdapter {
  final int? statusCode;
  final bool fail;
  int calls = 0;

  _StubAdapter({this.statusCode, this.fail = false});

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    calls++;
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{"status":"ok"}', statusCode!);
  }

  @override
  void close({bool force = false}) {}
}

HealthNotifier _health(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;
  return HealthNotifier(dio);
}

void _healthTests() {
  group('HealthNotifier', () {
    test('200 menjadikan status healthy', () async {
      final adapter = _StubAdapter(statusCode: 200);
      final notifier = _health(adapter);

      expect(await notifier.checkServerHealth(), isTrue);
      expect(notifier.state, HealthState.healthy);
    });

    test('status non-200 dianggap tidak sehat', () async {
      final adapter = _StubAdapter(statusCode: 503);
      final notifier = _health(adapter);

      expect(await notifier.checkServerHealth(), isFalse);
      expect(notifier.state, HealthState.unhealthy);
    });

    // Inti P7: versi lama mencoba 3× (10 detik + jeda 1 detik tiap kali),
    // menahan splash sampai ~32 detik. Pemulihan kini lewat tombol coba-lagi.
    test('gagal hanya sekali percobaan, tidak mengulang sendiri', () async {
      final adapter = _StubAdapter(fail: true);
      final notifier = _health(adapter);

      expect(await notifier.checkServerHealth(), isFalse);
      expect(notifier.state, HealthState.unhealthy);
      expect(adapter.calls, 1, reason: 'tidak boleh ada percobaan ulang');
    });

    test('kegagalan tidak melempar ke pemanggil', () async {
      final notifier = _health(_StubAdapter(fail: true));
      await expectLater(notifier.checkServerHealth(), completion(isFalse));
    });
  });
}
