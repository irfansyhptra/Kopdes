import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';
import 'package:kopdes/features/umkm/data/models/seller_model.dart';
import 'package:kopdes/features/umkm/presentation/widgets/seller_dashboard_sections.dart';

const _widths = <double>[320, 360, 390, 430, 600, 768, 1024];
const _textScales = <double>[1.0, 1.3, 1.5, 2.0];

SellerDashboardStats _stats({
  double today = 0,
  int todayOrders = 0,
  double monthly = 0,
  int monthlyOrders = 0,
  int products = 0,
  int sold = 0,
  double rating = 0,
  int lowStock = 0,
  int newOrders = 0,
}) => SellerDashboardStats(
  totalProducts: products,
  totalOrders: 0,
  productsSold: sold,
  todayEarnings: today,
  todayOrders: todayOrders,
  monthlyEarnings: monthly,
  monthlyOrders: monthlyOrders,
  storeRating: rating,
  lowStockCount: lowStock,
  newOrdersCount: newOrders,
);

Future<void> _pump(
  WidgetTester tester,
  double width,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Widget _quickActions() => QuickActionsRow(
  actions: [
    SellerQuickAction(
      icon: Icons.add_business_outlined,
      label: 'Tambah Produk',
      onTap: () {},
    ),
    SellerQuickAction(
      icon: Icons.receipt_long_outlined,
      label: 'Pesanan',
      onTap: () {},
    ),
    SellerQuickAction(
      icon: Icons.inventory_2_outlined,
      label: 'Stok',
      onTap: () {},
    ),
    SellerQuickAction(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Keuangan',
      onTap: () {},
    ),
  ],
);

Widget _attention({int newOrders = 0, int lowStock = 0}) => AttentionSection(
  onSeeAll: () {},
  items: [
    AttentionItem(
      icon: Icons.receipt_long_outlined,
      tint: AppColors.primary,
      title: 'Pesanan baru',
      urgentMessage: 'Menunggu diproses',
      calmMessage: 'Tidak ada pesanan yang menunggu',
      count: newOrders,
      onTap: () {},
    ),
    AttentionItem(
      icon: Icons.warning_amber_rounded,
      tint: AppColors.warning,
      title: 'Stok menipis',
      urgentMessage: 'Segera tambah stok produk Anda',
      calmMessage: 'Stok produk aman',
      count: lowStock,
      onTap: () {},
    ),
  ],
);

Widget _summary({double rating = 0}) => StoreSummaryGrid(
  cells: [
    const StoreSummaryCell(
      icon: Icons.inventory_2_outlined,
      tint: AppColors.success,
      label: 'Produk Aktif',
      value: '3',
    ),
    const StoreSummaryCell(
      icon: Icons.shopping_bag_outlined,
      tint: AppColors.primary,
      label: 'Terjual',
      value: '0',
    ),
    StoreSummaryCell(
      icon: Icons.star_outline_rounded,
      tint: AppColors.warning,
      label: 'Rating Toko',
      value: rating > 0 ? '4,8' : '—',
      note: rating > 0 ? null : 'Belum ada ulasan',
    ),
    const StoreSummaryCell(
      icon: Icons.bar_chart_rounded,
      tint: AppColors.primary,
      label: 'Kunjungan Toko',
      value: '—',
      note: 'Belum ada data',
    ),
  ],
);

void main() {
  group('tata letak dasbor penjual', () {
    for (final width in _widths) {
      testWidgets('tidak meluber pada ${width.toInt()}dp', (tester) async {
        await _pump(
          tester,
          width,
          Column(
            children: [
              SalesSummaryCard(
                stats: _stats(today: 1250000, monthly: 48750000),
              ),
              const SizedBox(height: AppSpacing.md),
              _quickActions(),
              const SizedBox(height: AppSpacing.md),
              _attention(newOrders: 12, lowStock: 3),
              const SizedBox(height: AppSpacing.md),
              _summary(rating: 4.8),
              const SizedBox(height: AppSpacing.md),
              StoreTipsRow(actionLabel: 'Lengkapi Profil', onTap: () {}),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak meluber pada 320dp skala ${scale}x', (tester) async {
        await _pump(
          tester,
          320,
          Column(
            children: [
              SalesSummaryCard(
                stats: _stats(today: 1250000, monthly: 48750000),
              ),
              const SizedBox(height: AppSpacing.md),
              _quickActions(),
              const SizedBox(height: AppSpacing.md),
              _attention(newOrders: 12, lowStock: 3),
              const SizedBox(height: AppSpacing.md),
              _summary(),
            ],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ringkasan penjualan', () {
    testWidgets('rupiah Indonesia dan jumlah transaksi', (tester) async {
      await _pump(
        tester,
        390,
        SalesSummaryCard(
          stats: _stats(
            today: 1250000,
            todayOrders: 7,
            monthly: 48750000,
            monthlyOrders: 142,
          ),
        ),
      );

      expect(find.text('Rp1.250.000'), findsOneWidget);
      expect(find.text('7 transaksi'), findsOneWidget);
      expect(find.text('Rp48.750.000'), findsOneWidget);
      expect(find.text('142 transaksi'), findsOneWidget);
    });

    testWidgets('belum ada transaksi: Rp0 dan 0 transaksi', (tester) async {
      await _pump(tester, 390, SalesSummaryCard(stats: _stats()));

      expect(find.text('Rp0'), findsNWidgets(2));
      expect(find.text('0 transaksi'), findsNWidgets(2));
    });
  });

  group('tindakan cepat', () {
    testWidgets('empat tindakan sebaris pada layar lega', (tester) async {
      await _pump(tester, 430, _quickActions());

      final row = tester.getSize(find.byType(QuickActionsRow));
      final first = tester.getTopLeft(find.text('Tambah Produk')).dy;
      final last = tester.getTopLeft(find.text('Keuangan')).dy;

      expect(first, last, reason: 'satu baris');
      expect(row.width, lessThanOrEqualTo(430));
    });

    // Dipecah dua baris, BUKAN dikecilkan fontnya sampai sulit dibaca.
    testWidgets('dua baris saat layar sempit dengan teks besar', (
      tester,
    ) async {
      await _pump(tester, 320, _quickActions(), textScale: 1.5);

      final first = tester.getTopLeft(find.text('Tambah Produk')).dy;
      final last = tester.getTopLeft(find.text('Keuangan')).dy;
      expect(last, greaterThan(first));
      expect(tester.takeException(), isNull);
    });

    testWidgets('area sentuh tiap tindakan nyaman', (tester) async {
      await _pump(tester, 390, _quickActions());

      for (final label in const [
        'Tambah Produk',
        'Pesanan',
        'Stok',
        'Keuangan',
      ]) {
        // ApplePressable memakai GestureDetector, bukan InkWell.
        final tile = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(ApplePressable),
            )
            .first;
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
      }
    });
  });

  group('perlu perhatian', () {
    // Nol bukan keadaan darurat.
    testWidgets('nol memakai kalimat netral', (tester) async {
      await _pump(tester, 390, _attention());

      expect(find.text('Tidak ada pesanan yang menunggu'), findsOneWidget);
      expect(find.text('Stok produk aman'), findsOneWidget);
      expect(find.text('Menunggu diproses'), findsNothing);
      expect(find.text('Segera tambah stok produk Anda'), findsNothing);
    });

    testWidgets('ada isinya memakai kalimat mendesak', (tester) async {
      await _pump(tester, 390, _attention(newOrders: 4, lowStock: 2));

      expect(find.text('Menunggu diproses'), findsOneWidget);
      expect(find.text('Segera tambah stok produk Anda'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tiap baris punya chevron dan bisa ditekan', (tester) async {
      var ditekan = 0;
      await _pump(
        tester,
        390,
        AttentionSection(
          items: [
            AttentionItem(
              icon: Icons.receipt_long_outlined,
              tint: AppColors.primary,
              title: 'Pesanan baru',
              urgentMessage: 'x',
              calmMessage: 'y',
              count: 1,
              onTap: () => ditekan++,
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Pesanan baru'));
      expect(ditekan, 1);
    });
  });

  group('ringkasan toko', () {
    testWidgets('rating kosong tampil garis, bukan nol', (tester) async {
      await _pump(tester, 390, _summary());

      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('Belum ada ulasan'), findsOneWidget);
      // Kunjungan belum didukung backend — garis, bukan angka rekaan.
      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('0,0'), findsNothing);
    });

    testWidgets('keempat sel tampil', (tester) async {
      await _pump(tester, 390, _summary(rating: 4.8));

      for (final label in const [
        'Produk Aktif',
        'Terjual',
        'Rating Toko',
        'Kunjungan Toko',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('4,8'), findsOneWidget);
    });
  });

  group('tips toko', () {
    testWidgets('tanpa tujuan: keterangan biasa, bukan tombol mati', (
      tester,
    ) async {
      await _pump(
        tester,
        390,
        const StoreTipsRow(actionLabel: 'Lengkapi Profil'),
      );

      expect(find.text('Tingkatkan toko Anda'), findsOneWidget);
      expect(find.text('Lengkapi Profil'), findsNothing);
      expect(find.byType(ApplePressable), findsNothing);
    });

    testWidgets('dengan tujuan: bisa ditekan', (tester) async {
      var ditekan = 0;
      await _pump(
        tester,
        390,
        StoreTipsRow(actionLabel: 'Lengkapi Profil', onTap: () => ditekan++),
      );

      expect(find.text('Lengkapi Profil'), findsOneWidget);
      await tester.tap(find.text('Tingkatkan toko Anda'));
      expect(ditekan, 1);
    });
  });
}
