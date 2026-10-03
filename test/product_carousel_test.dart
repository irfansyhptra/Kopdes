import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/marketplace/domain/marketplace.dart';
import 'package:kopdes/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:kopdes/features/marketplace/presentation/widgets/marketplace_product_card.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';
import 'package:kopdes/features/marketplace/presentation/widgets/product_carousel.dart';

/**
 * Carousel produk.
 *
 * Yang diperiksa: lebar kartu benar-benar jatuh di rentang yang dijanjikan
 * pada tiap kelas layar, dan tidak ada yang meluber — termasuk saat skala teks
 * dinaikkan, yang justru ketika daftar mendatar bertinggi tetap paling mudah
 * memotong teksnya.
 */

MarketplaceProduct _product(int i, {int stock = 10}) => MarketplaceProduct(
  id: 'p$i',
  name: 'Kopi Arabika Gayo 250 g',
  price: 65000,
  stock: stock,
  categoryId: 'c1',
  sellerName: 'UMKM Kopi Gayo',
  isUmkm: true,
  distanceLabel: '1,2 km',
  ratingAverage: 4.8,
  ratingCount: 128,
);

Future<double> _pumpCarousel(
  WidgetTester tester,
  double width, {
  double textScale = 1.0,
  int count = 6,
}) async {
  tester.view.physicalSize = Size(width * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  late double cardWidth;

  await tester.pumpWidget(
    ProviderScope(
      // Favorit menulis ke cache Isar, yang tidak dibuka di uji widget.
      overrides: [
        favoriteProductsProvider.overrideWith((ref) => FavoriteNotifier(null)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        // `copyWith`, bukan `MediaQueryData()` kosong: membuat data baru dari
        // nol menghapus `size`, dan lebar layar justru yang diukur di sini.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                cardWidth = productCardWidth(constraints.maxWidth);
                return ProductCarousel(
                  products: [for (var i = 0; i < count; i++) _product(i)],
                  onTap: (_) {},
                  onAddToCart: (_) {},
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cardWidth;
}

void main() {
  group('Lebar kartu sesuai kelas layar', () {
    testWidgets('320dp: 172–184dp', (tester) async {
      final w = await _pumpCarousel(tester, 320);
      expect(w, inInclusiveRange(172, 184));
    });

    testWidgets('360dp: 180–200dp', (tester) async {
      final w = await _pumpCarousel(tester, 360);
      expect(w, inInclusiveRange(180, 200));
    });

    testWidgets('375dp: 180–200dp', (tester) async {
      final w = await _pumpCarousel(tester, 375);
      expect(w, inInclusiveRange(180, 200));
    });

    testWidgets('430dp: 180–200dp', (tester) async {
      final w = await _pumpCarousel(tester, 430);
      expect(w, inInclusiveRange(180, 200));
    });

    testWidgets('768dp: tidak melebihi 200dp', (tester) async {
      final w = await _pumpCarousel(tester, 768);
      expect(w, lessThanOrEqualTo(200));
    });
  });

  group('Tidak overflow', () {
    for (final width in [320.0, 375.0, 430.0, 768.0]) {
      testWidgets('pada ${width.toInt()}dp', (tester) async {
        await _pumpCarousel(tester, width);
        expect(tester.takeException(), isNull);
      });
    }

    // Spesifikasi menuntut skala teks sampai 1,3 tanpa overflow; 2,0 diuji
    // sekalian karena daftar mendatar bertinggi tetap yang paling cepat
    // memotong teks.
    for (final scale in [1.3, 2.0]) {
      testWidgets('pada 320dp dengan skala teks ${scale}x', (tester) async {
        await _pumpCarousel(tester, 320, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  /// Slider rekomendasi di beranda memakai [AppleProductTile], yang isinya
  /// lebih pendek daripada kartu Marketplace dan karena itu punya anggaran
  /// tingginya sendiri. Angkanya diukur, jadi ia perlu penjaga sendiri.
  group('Kartu ringkas slider beranda', () {
    for (final (width, scale) in [
      (320.0, 1.0),
      (320.0, 1.3),
      (390.0, 1.3),
      (430.0, 2.0),
    ]) {
      testWidgets('tidak overflow ${width.toInt()}dp skala teks $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width * 3, 900 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final w = productCardWidth(constraints.maxWidth);
                  return SizedBox(
                    height: w / compactProductCardAspectRatio(context),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (_, __) => SizedBox(
                        width: w,
                        child: AppleProductTile(
                          imageUrl: '',
                          imageHeight: w,
                          // Nama terpanjang dan harga terbesar sekaligus:
                          // kombinasi yang paling cepat memotong teks.
                          title: 'Beras Premium Organik Pilihan Petani Lamteh',
                          subtitle: 'KMP Mitra Koperasi',
                          price: 'Rp999.999.999',
                          onTap: () {},
                          onAdd: () {},
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('daftar kosong tidak menyisakan ruang kosong', (tester) async {
    await _pumpCarousel(tester, 390, count: 0);
    expect(find.byType(MarketplaceProductCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
