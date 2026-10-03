import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/home/presentation/widgets/compact_home_header.dart';
import 'package:kopdes/features/home/presentation/widgets/home_header_delegate.dart';

const _widths = <double>[320, 360, 390, 430, 600, 768];
const _textScales = <double>[1.0, 1.3, 1.5, 2.0];

HomeHeaderDelegate _delegate(
  BuildContext context, {
  String lokasi = 'Lamgugop, Banda Aceh',
}) => HomeHeaderDelegate(
  userName: 'Teuku Zulfikar Maulana',
  userLocation: lokasi,
  notificationCount: 3,
  cartCount: 12,
  chatCount: 128,
  onNotificationTap: () {},
  onCartTap: () {},
  onChatTap: () {},
  onSearchTap: () {},
  onFilterTap: () {},
  height: CompactHomeHeader.expandedHeight(context),
);

Future<ScrollController> _pump(
  WidgetTester tester,
  double width, {
  double textScale = 1.0,
  String lokasi = 'Lamgugop, Banda Aceh',
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 44),
        ),
        child: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              Builder(
                builder: (context) => SliverPersistentHeader(
                  pinned: true,
                  delegate: _delegate(context, lokasi: lokasi),
                ),
              ),
              SliverList.builder(
                itemCount: 30,
                itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  group('kepala beranda menempel', () {
    for (final width in _widths) {
      testWidgets('tidak meluber pada ${width.toInt()}dp', (tester) async {
        await _pump(tester, width);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak meluber pada 360dp skala ${scale}x', (tester) async {
        await _pump(tester, 360, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('320dp skala 2.0x — kasus terberat', (tester) async {
      await _pump(tester, 320, textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    // Inilah inti permintaannya: pencarian tidak boleh ikut hilang saat
    // halaman digulir.
    testWidgets('pencarian tetap terlihat setelah digulir jauh', (
      tester,
    ) async {
      final controller = await _pump(tester, 390);
      expect(find.text('Cari produk kebutuhanmu...'), findsOneWidget);

      controller.jumpTo(600);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Cari produk kebutuhanmu...'),
        findsOneWidget,
        reason: 'kolom pencarian ikut menempel',
      );
    });

    // Inti permintaannya: SELURUH header dipaku, bukan hanya pencariannya.
    testWidgets('sapaan, nama, dan lokasi tetap terlihat setelah digulir', (
      tester,
    ) async {
      final controller = await _pump(tester, 390);
      expect(find.text('Lamgugop, Banda Aceh'), findsOneWidget);
      expect(find.text('Teuku Zulfikar Maulana'), findsOneWidget);

      controller.jumpTo(600);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Lamgugop, Banda Aceh'), findsOneWidget);
      expect(find.text('Teuku Zulfikar Maulana'), findsOneWidget);
    });

    testWidgets('ketiga kapsul aksi ikut menempel', (tester) async {
      final controller = await _pump(tester, 390);
      controller.jumpTo(600);
      await tester.pump();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      // Lencananya ikut, bukan hanya ikonnya. Dicari di dalam header saja:
      // daftar di bawahnya juga memuat angka-angka itu sebagai isinya.
      Finder diHeader(String angka) => find.descendant(
        of: find.byType(CompactHomeHeader),
        matching: find.text(angka),
      );
      expect(diHeader('3'), findsOneWidget);
      expect(diHeader('12'), findsOneWidget);
      expect(diHeader('99+'), findsOneWidget);
    });

    testWidgets('tingginya tidak berubah sama sekali saat digulir', (
      tester,
    ) async {
      final controller = await _pump(tester, 390);
      final before = tester.getSize(find.byType(CompactHomeHeader)).height;

      controller.jumpTo(600);
      await tester.pump();
      final after = tester.getSize(find.byType(CompactHomeHeader)).height;

      // Dipaku utuh: posisinya tidak berubah dari awal.
      expect(after, before);
    });

    testWidgets('puncak header tetap di tepi atas layar', (tester) async {
      final controller = await _pump(tester, 390);
      controller.jumpTo(600);
      await tester.pump();

      final top = tester.getTopLeft(find.byType(CompactHomeHeader)).dy;
      expect(top, 0);
    });

    testWidgets('teks lokasi datang dari luar, bukan dipaku di dalam', (
      tester,
    ) async {
      await _pump(tester, 390, lokasi: 'Mencari lokasi…');

      expect(find.text('Mencari lokasi…'), findsOneWidget);
      // Nama desa yang dulu dituliskan langsung untuk semua orang.
      expect(find.text('Desa Lamteh, Banda Aceh'), findsNothing);
    });
  });
}
