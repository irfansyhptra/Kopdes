import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/umkm/data/stock_live_repository.dart';

/// Menjawab /seller/inventory/live dari antrean yang disiapkan tiap tes,
/// sambil merekam setiap permintaan.
class _FeedAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> responses;
  final List<RequestOptions> requests = [];

  _FeedAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    requests.add(options);
    final body = responses.isEmpty
        ? {'movements': [], 'serverTime': 'T-kosong', 'hasMore': false}
        : responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': body}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({StockLiveRepository repo, _FeedAdapter adapter}) _harness(
  List<Map<String, dynamic>> responses,
) {
  final adapter = _FeedAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;
  return (repo: StockLiveRepository(dio), adapter: adapter);
}

Map<String, dynamic> _movement({
  String id = 'm1',
  String type = 'OUT',
  int quantity = 3,
  int stockAfter = 17,
  String? externalRef,
  String? recordedBy = 'Kasir Toko',
}) => {
  'id': id,
  'type': type,
  'quantity': quantity,
  'stockAfter': stockAfter,
  'reason': 'Penjualan kasir',
  'externalRef': externalRef,
  'recordedBy': recordedBy,
  'createdAt': '2026-10-03T10:00:00.000Z',
  'product': {'id': 'p1', 'name': 'Keripik Pisang', 'stock': stockAfter},
};

void main() {
  group('StockLiveRepository', () {
    test('tarikan pertama tanpa penanda', () async {
      final h = _harness([
        {'movements': [], 'serverTime': 'T1', 'hasMore': false},
      ]);
      await h.repo.fetch();

      expect(h.adapter.requests.single.path, '/seller/inventory/live');
      expect(
        h.adapter.requests.single.queryParameters.containsKey('since'),
        isFalse,
      );
    });

    test('penanda dari server dikirim kembali apa adanya', () async {
      final h = _harness([
        {'movements': [], 'serverTime': 'T2', 'hasMore': false},
      ]);
      await h.repo.fetch(since: 'T1');

      // Apa adanya, bukan diolah ulang jadi waktu lokal: jam perangkat dan
      // jam server tidak pernah sama persis.
      expect(h.adapter.requests.single.queryParameters['since'], 'T1');
    });

    test('pergerakan kasir dikenali dari nomor struknya', () async {
      final h = _harness([
        {
          'movements': [_movement(externalRef: 'STRUK-001')],
          'serverTime': 'T2',
          'hasMore': false,
        },
      ]);
      final chunk = await h.repo.fetch();

      final m = chunk.movements.single;
      expect(m.fromPos, isTrue);
      expect(m.externalRef, 'STRUK-001');
      expect(m.type, StockMovementType.keluar);
      expect(m.quantity, 3);
      expect(m.stockAfter, 17);
      expect(m.productName, 'Keripik Pisang');
      expect(m.recordedBy, 'Kasir Toko');
    });

    test('pergerakan dari aplikasi sendiri bukan dari kasir', () async {
      final h = _harness([
        {
          'movements': [_movement(externalRef: null, type: 'IN')],
          'serverTime': 'T2',
          'hasMore': false,
        },
      ]);
      final m = (await h.repo.fetch()).movements.single;

      expect(m.fromPos, isFalse);
      expect(m.type, StockMovementType.masuk);
    });

    test('tipe tak dikenal tidak menggagalkan seluruh tarikan', () async {
      final h = _harness([
        {
          'movements': [_movement(type: 'TIPE_BARU')],
          'serverTime': 'T2',
          'hasMore': false,
        },
      ]);
      final m = (await h.repo.fetch()).movements.single;

      // Jatuh ke koreksi, bukan melempar: versi server yang lebih baru tidak
      // boleh mematikan pemantauan di ponsel yang belum diperbarui.
      expect(m.type, StockMovementType.koreksi);
    });

    test('hasMore diteruskan supaya sisanya bisa ditarik', () async {
      final h = _harness([
        {
          'movements': [_movement()],
          'serverTime': 'T2',
          'hasMore': true,
        },
      ]);
      expect((await h.repo.fetch()).hasMore, isTrue);
    });

    test('respons kosong tetap sah', () async {
      final h = _harness([
        {'movements': [], 'serverTime': 'T9', 'hasMore': false},
      ]);
      final chunk = await h.repo.fetch();

      expect(chunk.movements, isEmpty);
      expect(chunk.cursor, 'T9');
      expect(chunk.hasMore, isFalse);
    });
  });
}
