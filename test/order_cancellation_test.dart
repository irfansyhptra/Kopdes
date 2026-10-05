import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/network/dio_client.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/order/data/cancellation_repository.dart';
import 'package:kopdes/features/order/data/cancellation_review_repository.dart';
import 'package:kopdes/features/order/domain/entities/order.dart';
import 'package:kopdes/features/order/presentation/screens/cancellation_review_screen.dart';
import 'package:kopdes/features/order/presentation/screens/cancellations_screen.dart';
import 'package:kopdes/features/umkm/data/store_scope.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? __,
  ) async {
    requests.add(o);
    return ResponseBody.fromString(
      jsonEncode(body ?? {'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter a) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = a;

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  double width = 390,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => home),
            GoRoute(
              path: '/orders/:id',
              builder: (_, s) => Text('detail ${s.pathParameters['id']}'),
            ),
          ],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('keadaan pengajuan diturunkan dari kolomnya', () {
    Order order({
      String status = 'PENDING',
      DateTime? requestedAt,
      DateTime? decidedAt,
    }) => Order(
      id: 'o1',
      customerId: 'c1',
      totalAmount: 95000,
      status: status,
      paymentMethod: 'COD',
      paymentStatus: 'PENDING',
      deliveryAddressId: 'a1',
      items: const [],
      createdAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
      cancelRequestedAt: requestedAt,
      cancelDecidedAt: decidedAt,
    );

    test('belum diajukan', () {
      expect(order().cancellation, CancellationState.none);
      expect(order().canRequestCancellation, isTrue);
    });

    test('diajukan, belum dijawab — tidak bisa diajukan dua kali', () {
      final o = order(requestedAt: DateTime(2026, 10, 6));
      expect(o.cancellation, CancellationState.requested);
      expect(o.canRequestCancellation, isFalse);
    });

    test('dijawab dan pesanan batal berarti disetujui', () {
      final o = order(
        status: 'CANCELLED',
        requestedAt: DateTime(2026, 10, 6),
        decidedAt: DateTime(2026, 10, 6),
      );
      expect(o.cancellation, CancellationState.approved);
    });

    test('dijawab tetapi pesanan jalan terus berarti ditolak', () {
      final o = order(
        requestedAt: DateTime(2026, 10, 6),
        decidedAt: DateTime(2026, 10, 6),
      );
      expect(o.cancellation, CancellationState.rejected);
    });

    // Setelah toko mulai menyiapkan, pembatalan diselesaikan dengan bicara.
    test('pesanan yang sudah diproses tidak bisa diajukan batal', () {
      expect(order(status: 'PROCESSING').canRequestCancellation, isFalse);
      expect(order(status: 'OUT_FOR_DELIVERY').canRequestCancellation, isFalse);
    });
  });

  group('halaman Pesanan Dibatalkan milik pembeli', () {
    Map<String, dynamic> payload(String state, {String? rejectReason}) => {
      'orders': [
        {
          'id': 'order-abcdef12',
          'status': state == 'APPROVED' ? 'CANCELLED' : 'PENDING',
          'paymentMethod': 'COD',
          'paymentStatus': 'PENDING',
          'totalAmount': 95000,
          'createdAt': '2026-10-06T01:00:00.000Z',
          'requestedAt': '2026-10-06T02:00:00.000Z',
          'reason': 'Salah alamat',
          'decidedAt': state == 'REQUESTED' ? null : '2026-10-06T03:00:00.000Z',
          'rejectReason': rejectReason,
          'cancellation': state,
          'items': [
            {'name': 'Beras 5 kg', 'quantity': 2},
          ],
        },
      ],
    };

    testWidgets('pengajuan yang menunggu disebut apa adanya', (tester) async {
      final a = _Adapter()..body = payload('REQUESTED');
      await _pump(
        tester,
        const CancellationsScreen(),
        overrides: [dioProvider.overrideWithValue(_dio(a))],
      );

      expect(a.requests.single.path, '/orders/cancellations');
      expect(find.text('Menunggu jawaban toko'), findsOneWidget);
      expect(find.text('Salah alamat'), findsOneWidget);
      expect(
        find.text('Pesanan ini masih berjalan sampai toko menjawab.'),
        findsOneWidget,
      );
    });

    testWidgets('penolakan menampilkan alasan toko', (tester) async {
      final a = _Adapter()
        ..body = payload('REJECTED', rejectReason: 'Barang sudah dikemas');
      await _pump(
        tester,
        const CancellationsScreen(),
        overrides: [dioProvider.overrideWithValue(_dio(a))],
      );

      expect(find.text('Pengajuan ditolak'), findsOneWidget);
      expect(find.text('Barang sudah dikemas'), findsOneWidget);
    });

    testWidgets('kosong: dijelaskan, bukan layar putih', (tester) async {
      final a = _Adapter()..body = {'orders': []};
      await _pump(
        tester,
        const CancellationsScreen(),
        overrides: [dioProvider.overrideWithValue(_dio(a))],
      );

      expect(find.text('Belum ada pesanan yang dibatalkan'), findsOneWidget);
    });
  });

  group('antrean pengajuan sisi toko', () {
    final pending = {
      'success': true,
      'data': [
        {
          'id': 'order-abcdef12',
          'status': 'PENDING',
          'totalAmount': 95000,
          'createdAt': '2026-10-06T01:00:00.000Z',
          'requestedAt': '2026-10-06T02:00:00.000Z',
          'reason': 'Salah alamat',
          'customerName': 'Ahmad Sobari',
          'items': [
            {'name': 'Beras 5 kg', 'quantity': 2},
          ],
        },
      ],
    };

    testWidgets('pengurus Kopdes memakai alamat /admin/orders', (tester) async {
      final a = _Adapter()..body = pending;
      await _pump(
        tester,
        const CancellationReviewScreen(),
        overrides: [
          dioProvider.overrideWithValue(_dio(a)),
          storeScopeProvider.overrideWithValue(StoreScope.kopdes),
        ],
      );

      expect(a.requests.single.path, '/admin/orders/cancellations');
      expect(find.textContaining('Ahmad Sobari'), findsOneWidget);
      expect(find.text('Salah alamat'), findsOneWidget);
    });

    testWidgets('penjual mitra memakai alamat /seller/orders', (tester) async {
      final a = _Adapter()..body = pending;
      await _pump(
        tester,
        const CancellationReviewScreen(),
        overrides: [
          dioProvider.overrideWithValue(_dio(a)),
          storeScopeProvider.overrideWithValue(StoreScope.umkm),
        ],
      );

      expect(a.requests.single.path, '/seller/orders/cancellations');
    });

    testWidgets('menyetujui mengirim approve true', (tester) async {
      final a = _Adapter()..body = pending;
      await _pump(
        tester,
        const CancellationReviewScreen(),
        overrides: [
          dioProvider.overrideWithValue(_dio(a)),
          storeScopeProvider.overrideWithValue(StoreScope.kopdes),
        ],
      );

      await tester.tap(find.text('Setujui Pembatalan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final patch = a.requests.firstWhere((r) => r.method == 'PATCH');
      expect(patch.path, '/admin/orders/order-abcdef12/cancellation');
      expect((patch.data as Map)['approve'], isTrue);
    });

    // Pembeli berhak tahu sebabnya, jadi penolakan tanpa alasan tidak dikirim.
    testWidgets('menolak tanpa alasan tidak mengirim apa pun', (tester) async {
      final a = _Adapter()..body = pending;
      await _pump(
        tester,
        const CancellationReviewScreen(),
        overrides: [
          dioProvider.overrideWithValue(_dio(a)),
          storeScopeProvider.overrideWithValue(StoreScope.kopdes),
        ],
      );

      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      // Tombol kirim mati selama alasannya kosong.
      final tolak = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Tolak').last,
      );
      expect(tolak.onPressed, isNull);

      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();
      expect(a.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });
  });

  group('tata letak', () {
    for (final width in [320.0, 390.0, 768.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('antrean toko tidak meluber ${width}dp ${scale}x', (
          tester,
        ) async {
          final a = _Adapter()
            ..body = {
              'success': true,
              'data': [
                {
                  'id': 'order-abcdef12',
                  'status': 'PENDING',
                  'totalAmount': 95000,
                  'createdAt': '2026-10-06T01:00:00.000Z',
                  'requestedAt': '2026-10-06T02:00:00.000Z',
                  'reason': 'Salah alamat pengiriman, mohon dibatalkan',
                  'customerName': 'Ahmad Sobari',
                  'items': [
                    {'name': 'Beras premium 5 kg', 'quantity': 2},
                  ],
                },
              ],
            };
          await _pump(
            tester,
            const CancellationReviewScreen(),
            overrides: [
              dioProvider.overrideWithValue(_dio(a)),
              storeScopeProvider.overrideWithValue(StoreScope.kopdes),
            ],
            width: width,
            scale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
