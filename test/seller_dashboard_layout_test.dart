import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/presentation/widgets/seller_header.dart';
import 'package:kopdes/shared/components/dashboard_card.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';

const _widths = <double>[320, 360, 390, 430, 600, 768];
const _textScales = <double>[1.0, 1.3, 1.5, 2.0];

Future<void> _pump(
  WidgetTester tester,
  double width,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

Widget _header({String storeName = 'Aceh Meutuah Swalayan Lamgugop'}) =>
    SellerHeader(
      storeName: storeName,
      statusLabel: 'Menunggu verifikasi pengurus Kopdes',
      isVerified: false,
      newOrderCount: 12,
      chatCount: 3,
      notificationCount: 128,
      onOrdersTap: () {},
      onChatTap: () {},
      onNotificationTap: () {},
      onSearchTap: () {},
      onAddProductTap: () {},
    );

Widget _statGrid(BuildContext context) => GridView(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
    mainAxisExtent: dashboardTileHeight(context),
  ),
  children: const [
    DashboardCard(
      title: 'Produk Aktif',
      value: '128',
      icon: Icons.inventory_2_outlined,
      iconColor: Colors.blue,
    ),
    DashboardCard(
      title: 'Pesanan Baru',
      value: '12',
      icon: Icons.notifications_active_outlined,
      iconColor: AppColors.warning,
      subtitle: 'Perlu diproses!',
    ),
  ],
);

void main() {
  group('kepala dasbor penjual', () {
    for (final width in _widths) {
      testWidgets('tidak meluber pada ${width.toInt()}dp', (tester) async {
        await _pump(tester, width, _header());
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak meluber pada 360dp skala ${scale}x', (tester) async {
        await _pump(tester, 360, _header(), textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('nama toko panjang dipotong, bukan mendorong kapsul', (
      tester,
    ) async {
      await _pump(
        tester,
        320,
        _header(storeName: 'Koperasi Serba Usaha Meutuah Jaya Abadi Sentosa'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiga kapsul aksi tampil dengan lencananya', (tester) async {
      await _pump(tester, 390, _header());

      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // Lebih dari 99 dipendekkan, bukan melebarkan kapsulnya.
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('inisial toko diambil dari dua kata pertama', (tester) async {
      await _pump(tester, 390, _header(storeName: 'Aceh Meutuah'));
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('satu kata pakai dua huruf pertamanya', (tester) async {
      await _pump(tester, 390, _header(storeName: 'Meutuah'));
      expect(find.text('ME'), findsOneWidget);
    });
  });

  group('grid angka dasbor', () {
    for (final width in _widths) {
      testWidgets('tidak meluber pada ${width.toInt()}dp', (tester) async {
        await _pump(
          tester,
          width,
          Builder(builder: (context) => _statGrid(context)),
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak meluber pada 320dp skala ${scale}x', (tester) async {
        await _pump(
          tester,
          320,
          Builder(builder: (context) => _statGrid(context)),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
