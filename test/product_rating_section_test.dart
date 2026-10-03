import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/network/dio_client.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/order/data/review_repository.dart';
import 'package:kopdes/features/product/presentation/widgets/product_detail_sections.dart';

/// Menjawab /reviews dengan sejumlah ulasan, sambil merekam permintaannya.
class _ReviewAdapter implements HttpClientAdapter {
  final int count;
  final double? average;
  RequestOptions? last;

  _ReviewAdapter({required this.count, this.average});

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'items': [
          for (var i = 0; i < count; i++)
            {
              'id': 'r$i',
              'rating': 5,
              'comment': 'Ulasan nomor $i',
              'createdAt': '2026-10-0${(i % 9) + 1}T09:00:00.000Z',
              'user': {'id': 'u$i', 'name': 'Pembeli $i'},
            },
        ],
        'averageRating': average,
        'meta': {'total': count},
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

Future<_ReviewAdapter> _pump(
  WidgetTester tester, {
  required int reviewCount,
  double? rating,
  int ratingCount = 0,
  double? average,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final adapter = _ReviewAdapter(count: reviewCount, average: average);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = adapter;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioProvider.overrideWithValue(dio)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: ProductReviewSection(
                target: const ReviewTarget.kopdes('p1'),
                ratingAverage: rating,
                ratingCount: ratingCount,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  group('section penilaian produk', () {
    testWidgets('angka, bintang, dan jumlah penilai tampil', (tester) async {
      await _pump(tester, reviewCount: 3, rating: 4.6, ratingCount: 128);

      expect(find.text('Penilaian Produk'), findsOneWidget);
      // Satu desimal, koma sebagai pemisah — sesuai penulisan Indonesia.
      expect(find.text('4,6'), findsOneWidget);
      expect(find.text('128 orang memberi penilaian'), findsOneWidget);
      // Diperiksa lewat label semantik, bukan menghitung ikon: tiap baris
      // ulasan juga menggambar bintangnya sendiri.
      expect(find.bySemanticsLabel('Penilaian 4,6 dari 5'), findsOneWidget);
    });

    testWidgets('tanpa penilaian: garis, bukan 0,0', (tester) async {
      await _pump(tester, reviewCount: 0);

      // Nol bukan nilai yang pernah bisa diberikan siapa pun — rentangnya
      // 1,0 sampai 5,0.
      expect(find.text('0,0'), findsNothing);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Belum ada yang menilai'), findsOneWidget);
      expect(find.bySemanticsLabel('Belum ada penilaian'), findsOneWidget);
    });

    testWidgets('keadaan kosong digambar, bukan sebaris teks abu-abu', (
      tester,
    ) async {
      await _pump(tester, reviewCount: 0);

      expect(find.text('Belum ada ulasan'), findsOneWidget);
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
      expect(find.textContaining('Jadilah yang pertama'), findsOneWidget);
    });

    // Halaman detail menampilkan cuplikan, bukan daftar lengkap.
    testWidgets('hanya meminta lima ulasan terbaru', (tester) async {
      final adapter = await _pump(tester, reviewCount: 5, rating: 5);

      expect(adapter.last!.queryParameters['limit'], 5);
      expect(adapter.last!.queryParameters['productId'], 'p1');
    });

    testWidgets('lima ulasan tampil semua', (tester) async {
      await _pump(tester, reviewCount: 5, rating: 5, ratingCount: 5);

      for (var i = 0; i < 5; i++) {
        expect(find.text('Ulasan nomor $i'), findsOneWidget);
      }
    });

    testWidgets('penilaian 5,0 penuh menampilkan lima bintang utuh', (
      tester,
    ) async {
      await _pump(tester, reviewCount: 1, rating: 5, ratingCount: 10);

      expect(find.bySemanticsLabel('Penilaian 5,0 dari 5'), findsOneWidget);
    });

    testWidgets('penilaian terendah 1,0 tetap menampilkan satu bintang', (
      tester,
    ) async {
      await _pump(tester, reviewCount: 1, rating: 1, ratingCount: 2);

      expect(find.text('1,0'), findsOneWidget);
      expect(find.bySemanticsLabel('Penilaian 1,0 dari 5'), findsOneWidget);
    });
  });

  group('section penilaian pada produk mitra UMKM', () {
    // Barang Kopdes dan barang mitra adalah dua tabel berbeda dengan dua
    // parameter berbeda di endpoint ulasan. Salah kirim dijawab 400.
    testWidgets('meminta ulasan lewat umkmProductId', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final adapter = _ReviewAdapter(count: 2, average: 4.0);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = adapter;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ProductReviewSection(
                  target: ReviewTarget.umkm('u1'),
                  ratingAverage: 4.0,
                  ratingCount: 9,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(adapter.last!.queryParameters['umkmProductId'], 'u1');
      expect(adapter.last!.queryParameters.containsKey('productId'), isFalse);
      expect(find.text('4,0'), findsOneWidget);
      expect(find.text('9 orang memberi penilaian'), findsOneWidget);
    });
  });
}
