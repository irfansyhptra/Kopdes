import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/data/models/product_category_model.dart';
import 'package:kopdes/features/umkm/data/models/product_model.dart';
import 'package:kopdes/shared/components/product_card.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';

/// Lebar yang wajib didukung, sama dengan berkas tata letak lain.
const _widths = <double>[320, 360, 390, 430, 600, 768];
const _textScales = <double>[1.0, 1.3, 1.5, 2.0];

ProductModel _product({
  String name = 'Madu Randu Asli Hutan Pedalaman Aceh Besar 500 ml',
  String category = 'Makanan & Minuman Olahan',
  int stock = 3,
  bool approved = false,
}) => ProductModel(
  id: 'p1',
  name: name,
  description: 'x',
  price: 1250000,
  stock: stock,
  categoryId: 'c1',
  category: ProductCategoryModel(id: 'c1', name: category),
  images: const [],
  isApproved: approved,
  isActive: true,
);

/// Membangun kartu di dalam grid yang sama persis dengan halaman produk.
Future<void> _pumpGrid(
  WidgetTester tester,
  double width, {
  double textScale = 1.0,
  int count = 4,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Builder(
            builder: (context) => GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.base),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: sellerProductCardMaxWidth,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: sellerProductCardHeight(context),
              ),
              itemCount: count,
              itemBuilder: (_, __) => ProductCard(
                product: _product(),
                onEdit: () {},
                onDelete: () {},
                onToggleActive: (_) {},
                onAdjustStock: (_) {},
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('kartu produk penjual tidak tumpang tindih', () {
    for (final width in _widths) {
      testWidgets('lebar ${width.toInt()}dp', (tester) async {
        await _pumpGrid(tester, width);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('360dp pada skala teks ${scale}x', (tester) async {
        await _pumpGrid(tester, 360, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('320dp pada skala teks 2.0x — kasus tersempit', (tester) async {
      await _pumpGrid(tester, 320, textScale: 2.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('aturan keras panduan desain', () {
    // Apple HIG: 44×44pt. Lambangnya boleh kecil, area sentuhnya tidak.
    testWidgets('setiap tombol punya area sentuh minimal 44pt', (tester) async {
      await _pumpGrid(tester, 390, count: 1);

      for (final icon in const [
        Icons.edit_outlined,
        Icons.delete_outline_rounded,
        Icons.visibility_outlined,
        Icons.add_rounded,
        Icons.remove_rounded,
      ]) {
        final target = find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(InkWell),
        );
        final size = tester.getSize(target.first);
        expect(
          size.height,
          greaterThanOrEqualTo(44.0),
          reason: '$icon tingginya ${size.height}',
        );
        expect(
          size.width,
          greaterThanOrEqualTo(40.0),
          reason: '$icon lebarnya ${size.width}',
        );
      }
    });

    // Status tidak pernah hanya warna. Tooltip tidak cukup: ia tidak muncul
    // pada sentuhan, jadi pengguna awas berjari tidak mendapat apa-apa.
    testWidgets('status verifikasi punya teks, bukan titik berwarna', (
      tester,
    ) async {
      await _pumpGrid(tester, 390, count: 1);
      expect(find.text('Belum tayang'), findsOneWidget);
    });

    testWidgets('status stok disebut dengan kata, bukan warna saja', (
      tester,
    ) async {
      await _pumpGrid(tester, 390, count: 1);
      // Produk contohnya berstok 3 — menipis.
      expect(find.textContaining('Menipis'), findsOneWidget);
    });
  });

  group('isi kartu tetap terbaca', () {
    testWidgets('harga, stok, status, dan kontrol semuanya tampil', (
      tester,
    ) async {
      await _pumpGrid(tester, 390, count: 1);

      expect(find.text('Rp1.250.000'), findsOneWidget);
      // Stok dan kendalinya ada di kartu — halaman Stok terpisah dilebur.
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
