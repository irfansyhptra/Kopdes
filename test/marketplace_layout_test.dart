import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/discovery/domain/discovery.dart';
import 'package:kopdes/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:kopdes/features/discovery/presentation/widgets/discovery_sections.dart';
import 'package:kopdes/features/marketplace/domain/marketplace.dart';
import 'package:kopdes/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:kopdes/features/marketplace/presentation/widgets/marketplace_product_card.dart';

/// Ukuran layar yang wajib didukung, sesuai spesifikasi.
const _sizes = <(String, double, double)>[
  ('320x568', 320, 568),
  ('360x800', 360, 800),
  ('390x844', 390, 844),
  ('430x932', 430, 932),
  ('600x960', 600, 960),
  ('768x1024', 768, 1024),
  ('1024x1366', 1024, 1366),
];

const _textScales = <double>[1.0, 1.3, 1.5, 2.0];

MarketplaceProduct _product({
  String name = 'Beras Premium 5 kg',
  String seller = 'Kopdes Lamteh',
  bool isUmkm = false,
  int stock = 10,
  double price = 64000,
  double? rating = 4.8,
  int ratingCount = 128,
}) => MarketplaceProduct(
  id: 'p1',
  name: name,
  price: price,
  stock: stock,
  categoryId: 'c1',
  sellerName: seller,
  isUmkm: isUmkm,
  ratingAverage: rating,
  ratingCount: ratingCount,
);

/// Merender grid seperti di layar: lebar kolom dihitung dari lebar layar.
Future<void> _pumpGrid(
  WidgetTester tester,
  double width,
  double height,
  List<MarketplaceProduct> products, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      // Favorit menulis ke cache Isar, yang tidak dibuka di uji widget.
      overrides: [
        favoriteProductsProvider.overrideWith((ref) => FavoriteNotifier(null)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            backgroundColor: AppColors.surfaceSoft,
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: (0.62 / textScale.clamp(1.0, 1.6))
                          .clamp(0.38, 0.62),
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) => MarketplaceProductCard(
                      product: products[i],
                      onTap: () {},
                      onAddToCart: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Grid produk tidak overflow', () {
    final products = [
      _product(),
      _product(name: 'Kue Adee', seller: 'Dapur Kak Nur', isUmkm: true),
      _product(name: 'Kopi Arabika Gayo', seller: 'Kopi Lamteh', isUmkm: true),
      _product(name: 'Minyak Goreng 2 L', seller: 'Kopdes Lambhuk'),
    ];

    for (final (label, w, h) in _sizes) {
      testWidgets('pada $label', (tester) async {
        await _pumpGrid(tester, w, h, products);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('pada 360dp dengan text scale ${scale}x', (tester) async {
        await _pumpGrid(tester, 360, 800, products, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    // Layar tersempit digabung dengan teks terbesar — kombinasi paling berat.
    testWidgets('320dp dengan text scale 2.0x', (tester) async {
      await _pumpGrid(tester, 320, 568, products, textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nama produk sangat panjang tidak meluber', (tester) async {
      await _pumpGrid(tester, 320, 568, [
        _product(
          name:
              'Beras Premium Organik Pilihan Petani Desa Lamteh '
              'Kemasan Karung 25 Kilogram Kualitas Ekspor',
          seller: 'Koperasi Desa Merah Putih Lamteh Ulee Kareng Banda Aceh',
        ),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('harga sangat besar tidak meluber', (tester) async {
      await _pumpGrid(tester, 320, 568, [_product(price: 999999999)]);
      expect(tester.takeException(), isNull);
    });
  });

  group('Isi kartu', () {
    testWidgets('menampilkan nama, penjual, rating, dan harga', (tester) async {
      await _pumpGrid(tester, 390, 844, [_product()]);

      expect(find.text('Beras Premium 5 kg'), findsOneWidget);
      expect(find.text('Kopdes Lamteh'), findsOneWidget);
      expect(find.text('4,8 (128)'), findsOneWidget);
      expect(find.text('Rp64.000'), findsOneWidget);
    });

    // Warna saja tidak cukup membedakan sumber penjual.
    testWidgets('lencana penjual ditulis sebagai teks', (tester) async {
      await _pumpGrid(tester, 390, 844, [
        _product(),
        _product(isUmkm: true, name: 'Kue Adee'),
      ]);

      expect(find.text('Kopdes'), findsOneWidget);
      expect(find.text('UMKM'), findsOneWidget);
    });

    testWidgets('stok habis ditandai teks, bukan hanya warna', (tester) async {
      await _pumpGrid(tester, 390, 844, [_product(stock: 0)]);
      expect(find.text('Stok habis'), findsOneWidget);
    });

    testWidgets('tanpa ulasan tidak menampilkan bintang nol', (tester) async {
      await _pumpGrid(tester, 390, 844, [
        _product(rating: null, ratingCount: 0),
      ]);

      expect(find.text('Belum ada ulasan'), findsOneWidget);
      expect(find.text('0,0 (0)'), findsNothing);
    });
  });

  // Favorit disimpan sebagai JSON lalu dibaca kembali lewat fromJson yang
  // sama dengan respons server — kalau round-trip ini putus, daftar favorit
  // kembali kosong setelah aplikasi ditutup.
  group('MarketplaceProduct round-trip favorit', () {
    test('menyimpan lalu membaca kembali menghasilkan produk yang sama', () {
      final original = _product(isUmkm: true, stock: 0, rating: 4.2);
      final restored = MarketplaceProduct.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.stock, original.stock);
      expect(restored.sellerName, original.sellerName);
      expect(restored.isUmkm, original.isUmkm);
      expect(restored.categoryId, original.categoryId);
      expect(restored.ratingAverage, original.ratingAverage);
      expect(restored.ratingCount, original.ratingCount);
      expect(restored.isOutOfStock, isTrue);
    });

    test('produk tanpa ulasan tetap tanpa ulasan setelah dibaca ulang', () {
      final restored = MarketplaceProduct.fromJson(
        _product(rating: null, ratingCount: 0).toJson(),
      );
      expect(restored.hasRating, isFalse);
      expect(restored.isUmkm, isFalse);
    });
  });

  group('MarketplaceFilter', () {
    // Backend hanya menerima satu categoryId; memilih di satu baris harus
    // mengosongkan baris lain agar keduanya tidak saling menimpa diam-diam.
    test('memilih kategori makanan mengosongkan kategori ritel', () {
      const filter = MarketplaceFilter(retailCategoryId: 'r1');
      final next = filter.copyWith(foodCategoryId: 'f1', clearRetail: true);

      expect(next.foodCategoryId, 'f1');
      expect(next.retailCategoryId, isNull);
      expect(next.categoryId, 'f1');
    });

    test('filter kosong berarti tidak ada filter aktif', () {
      expect(const MarketplaceFilter().hasActiveFilter, isFalse);
      expect(const MarketplaceFilter(search: 'beras').hasActiveFilter, isTrue);
      expect(
        const MarketplaceFilter(sellerType: SellerType.umkm).hasActiveFilter,
        isTrue,
      );
    });

    test('Terdekat memakai sort distance, bukan sellerType tersendiri', () {
      expect(SellerType.nearest.wire, 'ALL');
      const filter = MarketplaceFilter(sort: MarketplaceSort.distance);
      expect(filter.isDistanceSort, isTrue);
    });

    test('clearPrice menghapus kedua batas harga', () {
      const filter = MarketplaceFilter(minPrice: 1000, maxPrice: 5000);
      final next = filter.copyWith(clearPrice: true);
      expect(next.minPrice, isNull);
      expect(next.maxPrice, isNull);
    });

    test('radius ikut dihitung sebagai filter aktif', () {
      expect(const MarketplaceFilter(radiusKm: 3).hasActiveFilter, isTrue);
      final cleared = const MarketplaceFilter(
        radiusKm: 3,
      ).copyWith(clearRadius: true);
      expect(cleared.radiusKm, isNull);
    });
  });

  group('Banner Marketplace', () {
    for (final (label, w, h) in _sizes) {
      testWidgets('tidak overflow pada $label', (tester) async {
        await _pumpBanner(tester, w, h);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak overflow pada 320dp text scale ${scale}x', (
        tester,
      ) async {
        await _pumpBanner(tester, 320, 568, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    // Banner harus datang dari API. Isi bawaan hanya cadangan saat endpoint
    // belum menjawab atau admin belum memasang apa pun.
    testWidgets('memakai isi dari API bila tersedia', (tester) async {
      await _pumpBanner(
        tester,
        390,
        844,
        banners: const [
          PromoBanner(
            id: 'b1',
            badge: 'PROMO ADMIN',
            title: 'Iklan dari',
            highlight: 'Backend',
            description: 'Dipasang lewat panel admin.',
            ctaLabel: 'Buka',
          ),
        ],
      );

      expect(find.text('PROMO ADMIN'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);
      expect(find.text('PROMO HARI INI'), findsNothing);
    });

    testWidgets('jatuh ke isi bawaan saat API kosong', (tester) async {
      await _pumpBanner(tester, 390, 844);

      expect(find.text('PROMO HARI INI'), findsOneWidget);
      expect(find.text('Belanja Sekarang'), findsOneWidget);
    });

    testWidgets('bergeser sendiri saat ada lebih dari satu iklan', (
      tester,
    ) async {
      await _pumpBanner(tester, 390, 844, banners: _twoBanners);
      expect(_currentPage(tester), moreOrLessEquals(0, epsilon: 0.01));

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));

      expect(_currentPage(tester), moreOrLessEquals(1, epsilon: 0.01));
    });

    // Banner yang tetap bergeser sendiri setelah pengguna menyentuhnya akan
    // merebut slide yang sedang dibaca.
    testWidgets('berhenti bergeser setelah pengguna berinteraksi', (
      tester,
    ) async {
      await _pumpBanner(tester, 390, 844, banners: _twoBanners);

      // Geseran kecil: kembali ke slide semula, tetapi tetap dihitung sebagai
      // interaksi pengguna.
      await tester.drag(find.byType(PageView), const Offset(-12, 0));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 600));

      expect(_currentPage(tester), moreOrLessEquals(0, epsilon: 0.01));
    });

    // Timer yang tidak dibersihkan membuat flutter_test gagal dengan
    // "A Timer is still pending" saat widget dibuang.
    testWidgets('membersihkan timer saat widget dilepas', (tester) async {
      await _pumpBanner(tester, 390, 844, banners: _twoBanners);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
    });
  });
}

/// Halaman yang sedang tampil. Dibaca dari controller, bukan dari teks: PageView
/// tetap membangun halaman tetangga di luar layar, jadi menemukan teksnya tidak
/// membuktikan halaman itulah yang terlihat.
double? _currentPage(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller?.page;

const _twoBanners = <PromoBanner>[
  PromoBanner(id: 'b1', title: 'Slide Satu', ctaLabel: 'Satu'),
  PromoBanner(id: 'b2', title: 'Slide Dua', ctaLabel: 'Dua'),
];

/// Merender [BannerSection] sungguhan — termasuk perhitungan tinggi adaptif
/// dan jalur cadangannya — dengan `bannersProvider` diganti data uji.
Future<void> _pumpBanner(
  WidgetTester tester,
  double width,
  double height, {
  double textScale = 1.0,
  List<PromoBanner> banners = const [],
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [bannersProvider.overrideWith((ref) async => banners)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(
            backgroundColor: AppColors.surfaceSoft,
            body: SingleChildScrollView(child: BannerSection()),
          ),
        ),
      ),
    ),
  );
  // Satu pump untuk menyelesaikan Future provider, satu lagi untuk framenya.
  await tester.pump();
  await tester.pump();
}
