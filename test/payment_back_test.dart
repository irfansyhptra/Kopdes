import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/payment/data/payment_repository.dart';
import 'package:kopdes/features/payment/presentation/payment_screen.dart';

/// Tagihan yang sudah lunas: tidak menyalakan timer polling, jadi tesnya
/// bisa `pumpAndSettle` tanpa menunggu selamanya.
const _paid = PaymentInstructions(
  status: PayStatus.paid,
  amount: 95000,
  // `qris` ada di versi lama maupun versi Snap, jadi tes ini tidak ikut
  // berubah saat daftar metodenya dirapikan.
  method: OnlineMethod.qris,
);

class _FakeRepo implements PaymentRepository {
  @override
  Future<PaymentInstructions> payOrder(String orderId, OnlineMethod m) async =>
      _paid;

  @override
  Future<PaymentInstructions> topUpStatus(String id) async => _paid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dimulai LANGSUNG di layar bayar, meniru `context.go` dari checkout yang
/// mengganti seluruh tumpukan halaman — tidak ada apa pun untuk di-`pop`.
Future<GoRouter> _pump(WidgetTester tester, String initial) async {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/pay/order/:id',
        builder: (_, s) => PaymentScreen(
          target: (
            topUp: false,
            id: s.pathParameters['id'] ?? '',
            method: 'MIDTRANS',
          ),
        ),
      ),
      GoRoute(
        path: '/pay/topup/:id',
        builder: (_, s) => PaymentScreen(
          target: (topUp: true, id: s.pathParameters['id'] ?? '', method: ''),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, s) => Text('detail pesanan ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/wallet', builder: (_, __) => const Text('dompet')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [paymentRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('keluar dari layar pembayaran', () {
    testWidgets('tanpa halaman sebelumnya, kembali menuju detail pesanan', (
      tester,
    ) async {
      final router = await _pump(tester, '/pay/order/o1');
      expect(find.text('Pembayaran'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/orders/o1');
      expect(find.text('detail pesanan o1'), findsOneWidget);
    });

    testWidgets('isi ulang saldo kembali ke dompet', (tester) async {
      final router = await _pump(tester, '/pay/topup/t1');

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/wallet');
    });

    testWidgets(
      'tombol kembali ponsel juga berfungsi, tidak menutup aplikasi',
      (tester) async {
        final router = await _pump(tester, '/pay/order/o1');

        // Sama dengan menekan tombol kembali perangkat.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/orders/o1');
      },
    );
  });
}
