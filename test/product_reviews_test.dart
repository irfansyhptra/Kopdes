import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/network/dio_client.dart';
import 'package:kopdes/features/order/data/review_repository.dart';

/// Menjawab /reviews dengan muatan tetap, sambil merekam permintaannya.
class _ReviewAdapter implements HttpClientAdapter {
  final Object body;
  RequestOptions? last;

  _ReviewAdapter(this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({ProviderContainer container, _ReviewAdapter adapter}) _harness(Object body) {
  final adapter = _ReviewAdapter(body);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;

  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  return (container: container, adapter: adapter);
}

const _payload = {
  'success': true,
  'items': [
    {
      'id': 'r1',
      'rating': 5,
      'comment': 'Barangnya sesuai deskripsi.',
      'createdAt': '2026-10-01T09:00:00.000Z',
      'user': {'id': 'u1', 'name': 'Nurhayati'},
    },
    {
      'id': 'r2',
      'rating': 4,
      'comment': null,
      'createdAt': '2026-09-28T09:00:00.000Z',
      'user': {'id': 'u2', 'name': 'Teuku Iskandar'},
    },
  ],
  'averageRating': 4.5,
  'meta': {'total': 7, 'page': 1, 'limit': 5, 'totalPages': 2},
};

void main() {
  group('productReviewsProvider', () {
    test('produk UMKM dikirim sebagai umkmProductId', () async {
      final h = _harness(_payload);
      await h.container.read(
        productReviewsProvider(const ReviewTarget.umkm('p1')).future,
      );

      expect(h.adapter.last!.path, '/reviews');
      expect(h.adapter.last!.queryParameters['umkmProductId'], 'p1');
      // Endpoint menolak 400 bila keduanya dikirim bersamaan.
      expect(h.adapter.last!.queryParameters.containsKey('productId'), isFalse);
    });

    test('produk Kopdes dikirim sebagai productId', () async {
      final h = _harness(_payload);
      await h.container.read(
        productReviewsProvider(const ReviewTarget.kopdes('k1')).future,
      );

      expect(h.adapter.last!.queryParameters['productId'], 'k1');
      expect(
        h.adapter.last!.queryParameters.containsKey('umkmProductId'),
        isFalse,
      );
    });

    test('ulasan, rata-rata, dan total terbaca', () async {
      final h = _harness(_payload);
      final page = await h.container.read(
        productReviewsProvider(const ReviewTarget.umkm('p1')).future,
      );

      expect(page.items, hasLength(2));
      expect(page.averageRating, 4.5);
      // Total dari meta, bukan panjang halaman — inilah yang membuat
      // "+2 ulasan lainnya" benar.
      expect(page.total, 7);

      expect(page.items.first.reviewerName, 'Nurhayati');
      expect(page.items.first.rating, 5);
      expect(page.items.first.comment, 'Barangnya sesuai deskripsi.');
      // Ulasan tanpa komentar sah: bintang saja.
      expect(page.items[1].comment, isNull);
    });

    test('tanpa ulasan: kosong dan tanpa rata-rata', () async {
      final h = _harness({
        'success': true,
        'items': [],
        'averageRating': null,
        'meta': {'total': 0, 'page': 1, 'limit': 5, 'totalPages': 1},
      });
      final page = await h.container.read(
        productReviewsProvider(const ReviewTarget.umkm('p1')).future,
      );

      expect(page.items, isEmpty);
      // Null, bukan 0.0: "belum ada penilaian" bukan "dinilai nol bintang".
      expect(page.averageRating, isNull);
      expect(page.total, 0);
    });

    test('nama pengulas yang hilang tidak mengosongkan ulasannya', () async {
      final h = _harness({
        'items': [
          {'id': 'r1', 'rating': 3, 'createdAt': '2026-10-01T09:00:00.000Z'},
        ],
        'averageRating': 3,
        'meta': {'total': 1},
      });
      final page = await h.container.read(
        productReviewsProvider(const ReviewTarget.umkm('p1')).future,
      );

      expect(page.items.single.reviewerName, 'Pembeli');
      expect(page.items.single.rating, 3);
    });

    test('target berbeda tidak berbagi cache provider', () {
      expect(
        const ReviewTarget.umkm('x'),
        isNot(equals(const ReviewTarget.kopdes('x'))),
      );
      expect(
        const ReviewTarget.umkm('x'),
        equals(const ReviewTarget.umkm('x')),
      );
    });
  });
}
