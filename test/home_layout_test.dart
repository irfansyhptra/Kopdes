import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/home/presentation/widgets/compact_home_header.dart';
import 'package:kopdes/features/home/presentation/widgets/category_list_widget.dart';
import 'package:kopdes/features/home/presentation/widgets/compact_promo_banner.dart';
import 'package:kopdes/features/home/presentation/widgets/membership_summary_card.dart';

/// Lebar perangkat yang harus didukung, dari ponsel kecil sampai tablet.
const _widths = <double>[320, 360, 375, 414, 430, 768];

Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

Widget _header() => CompactHomeHeader(
  userName: 'Budi Santoso',
  userLocation: 'Desa Lamteh, Banda Aceh',
  notificationCount: 5,
  cartCount: 3,
  chatCount: 2,
  onNotificationTap: () {},
  onCartTap: () {},
  onChatTap: () {},
  onSearchTap: () {},
  onFilterTap: () {},
);

Widget _card() => MembershipSummaryCard(
  balance: 'Rp250.000',
  points: '1.250',
  statusLabel: 'VIP',
  onTopUpTap: () {},
  onHistoryTap: () {},
  onCouponTap: () {},
  onDetailTap: () {},
);

Widget _banner() => CompactPromoBanner(
  items: CompactPromoBanner.defaultItems,
  onCtaTap: (_) {},
);

Widget _categories() =>
    CategoryListWidget(onCategoryTap: (_) {}, onSeeAllTap: () {});

void main() {
  group('Beranda tidak overflow', () {
    for (final width in _widths) {
      testWidgets('header pada ${width.toInt()}dp', (tester) async {
        await _pumpAt(tester, width, _header());
        expect(tester.takeException(), isNull);
      });

      testWidgets('membership card pada ${width.toInt()}dp', (tester) async {
        await _pumpAt(tester, width, _card());
        expect(tester.takeException(), isNull);
      });

      testWidgets('banner promo pada ${width.toInt()}dp', (tester) async {
        await _pumpAt(tester, width, _banner());
        expect(tester.takeException(), isNull);
      });

      testWidgets('kategori pada ${width.toInt()}dp', (tester) async {
        await _pumpAt(tester, width, _categories());
        expect(tester.takeException(), isNull);
      });
    }

    // Nama panjang tidak boleh mendorong tombol ikon keluar layar.
    testWidgets('nama pengguna panjang tetap aman di 320dp', (tester) async {
      await _pumpAt(
        tester,
        320,
        CompactHomeHeader(
          userName: 'Muhammad Abdurrahman Syahputra Al-Fatih',
          userLocation: 'Desa Lamteh Kecamatan Ulee Kareng, Banda Aceh',
          notificationCount: 128,
          cartCount: 99,
          chatCount: 12,
          onNotificationTap: () {},
          onCartTap: () {},
          onChatTap: () {},
          onSearchTap: () {},
          onFilterTap: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // Pengguna yang menaikkan ukuran teks sistem tidak boleh melihat
    // layout yang pecah.
    testWidgets('text scaling 1.3x pada 360dp', (tester) async {
      await _pumpAt(tester, 360, _card(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('Konten beranda', () {
    testWidgets('header menampilkan identitas & jumlah badge', (tester) async {
      await _pumpAt(tester, 375, _header());

      expect(find.text('Selamat Datang Kembali,'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Desa Lamteh, Banda Aceh'), findsOneWidget);
      expect(find.text('Cari produk kebutuhanmu...'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // notifikasi
    });

    // Label aksi cepat harus terbaca utuh — versi sebelumnya memotongnya
    // jadi "Top Up Sal…".
    testWidgets('label aksi cepat tidak terpotong', (tester) async {
      await _pumpAt(tester, 320, _card());

      for (final label in ['Top Up', 'Riwayat', 'Kupon', 'Detail']) {
        final widget = tester.widget<Text>(find.text(label));
        expect(widget.overflow, TextOverflow.ellipsis);
        // Terpotong atau tidak diputuskan saat melukis; yang bisa diperiksa
        // di sini: teksnya utuh, bukan hasil pemotongan manual.
        expect(widget.data, label);
      }
    });

    testWidgets('badge tersembunyi saat hitungannya nol', (tester) async {
      await _pumpAt(
        tester,
        375,
        CompactHomeHeader(
          userName: 'Budi',
          userLocation: 'Lamteh',
          notificationCount: 0,
          cartCount: 0,
          chatCount: 0,
          onNotificationTap: () {},
          onCartTap: () {},
          onChatTap: () {},
          onSearchTap: () {},
          onFilterTap: () {},
        ),
      );
      expect(find.text('0'), findsNothing);
    });

    testWidgets('banner menampilkan slide pertama & CTA-nya', (tester) async {
      await _pumpAt(tester, 375, _banner());

      expect(find.text('GRATIS ONGKIR'), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsOneWidget);
    });

    testWidgets('CTA banner memanggil callback', (tester) async {
      PromoBannerItem? tapped;
      await _pumpAt(
        tester,
        375,
        CompactPromoBanner(
          items: CompactPromoBanner.defaultItems,
          onCtaTap: (item) => tapped = item,
        ),
      );

      await tester.tap(find.text('Pesan Sekarang'));
      await tester.pumpAndSettle();

      expect(tapped?.badge, 'GRATIS ONGKIR');
    });
  });
}
