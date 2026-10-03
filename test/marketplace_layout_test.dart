import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/discovery/domain/discovery.dart';
import 'package:kopdes/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:kopdes/features/discovery/presentation/widgets/discovery_sections.dart';
import 'package:kopdes/features/marketplace/domain/marketplace.dart';
import 'package:kopdes/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:kopdes/features/marketplace/presentation/widgets/marketplace_filters.dart';
import 'package:kopdes/shared/widgets/category_image_card.dart';
import 'package:kopdes/features/marketplace/presentation/widgets/marketplace_product_card.dart';
import 'package:kopdes/features/product/domain/entities/category.dart';

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
  double? discountPrice,
  int soldCount = 0,
}) => MarketplaceProduct(
  id: 'p1',
  name: name,
  price: price,
  discountPrice: discountPrice,
  stock: stock,
  categoryId: 'c1',
  sellerName: seller,
  isUmkm: isUmkm,
  ratingAverage: rating,
  ratingCount: ratingCount,
  soldCount: soldCount,
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
            body: Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid.builder(
                      // Delegate yang sama dengan layar: salinan angka di sini
                      // pernah membuat uji hijau sementara kartu sungguhan
                      // meluber.
                      gridDelegate: marketplaceGridDelegate(context),
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
    ),
  );
  await tester.pump();
}

/// Merender satu baris filter kategori seperti di layar.
Future<void> _pumpFilterRow(
  WidgetTester tester,
  double width,
  double height, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            backgroundColor: AppColors.surfaceSoft,
            body: CategoryFilterRow(
              title: 'Filter Makanan',
              categories: const [
                Category(id: 'c1', name: 'Minuman', group: 'FOOD'),
                Category(id: 'c2', name: 'Cemilan', group: 'FOOD'),
                Category(id: 'c3', name: 'Kesehatan & Kecantikan'),
              ],
              selectedId: null,
              onSelected: (_) {},
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
      await _pumpGrid(tester, 390, 844, [_product(soldCount: 42)]);

      expect(find.text('Beras Premium 5 kg'), findsOneWidget);
      expect(find.text('Kopdes Lamteh'), findsOneWidget);
      expect(find.text('4,8'), findsOneWidget);
      expect(find.text('Rp64.000'), findsOneWidget);
      // Keterangan yang benar-benar dipakai pembeli untuk memutuskan.
      expect(find.textContaining('Stok 10'), findsOneWidget);
      expect(find.textContaining('42 terjual'), findsOneWidget);
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

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('0,0 (0)'), findsNothing);
      // Kalimat yang memakan satu baris penuh untuk mengatakan tidak ada
      // yang bisa dikatakan — diganti keterangan yang selalu punya isi.
      expect(find.text('Belum ada ulasan'), findsNothing);
      expect(find.textContaining('Stok 10'), findsOneWidget);
    });

    testWidgets('belum ada yang terjual tidak menampilkan "0 terjual"', (
      tester,
    ) async {
      await _pumpGrid(tester, 390, 844, [_product(soldCount: 0)]);
      expect(find.textContaining('terjual'), findsNothing);
    });

    testWidgets('stok habis tidak diulang di baris keterangan', (tester) async {
      await _pumpGrid(tester, 390, 844, [_product(stock: 0, soldCount: 7)]);

      // Lencana di atas gambar sudah menyampaikannya.
      expect(find.text('Stok habis'), findsOneWidget);
      expect(find.textContaining('Stok 0'), findsNothing);
      expect(find.textContaining('7 terjual'), findsOneWidget);
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

    test('diskon dan rating minimum dihitung sebagai filter aktif', () {
      expect(
        const MarketplaceFilter(discountedOnly: true).hasActiveFilter,
        isTrue,
      );
      expect(const MarketplaceFilter(minRating: 4).hasActiveFilter, isTrue);
      // Rating 0 berarti tanpa batas bawah, bukan "rating nol".
      expect(const MarketplaceFilter(minRating: 0).hasActiveFilter, isFalse);
    });

    test('radius ikut dihitung sebagai filter aktif', () {
      expect(const MarketplaceFilter(radiusKm: 3).hasActiveFilter, isTrue);
      final cleared = const MarketplaceFilter(
        radiusKm: 3,
      ).copyWith(clearRadius: true);
      expect(cleared.radiusKm, isNull);
    });
  });

  group('Diskon', () {
    // Backend menolak `discountPrice >= price` (`assertPricing`), jadi
    // `price` selalu harga normal dan `discountPrice` harga yang dibayar.
    test('harga diskon di atas harga normal bukan diskon', () {
      final product = _product(price: 64000, discountPrice: 80000);
      expect(product.hasDiscount, isFalse);
      expect(product.discountPercent, 0);
      expect(product.effectivePrice, 64000);
    });

    test('persentase dihitung dari harga normal', () {
      final product = _product(price: 80000, discountPrice: 64000);
      expect(product.hasDiscount, isTrue);
      expect(product.discountPercent, 20);
      expect(product.effectivePrice, 64000);
    });

    test('tanpa harga diskon tidak ada diskon', () {
      expect(_product().hasDiscount, isFalse);
      expect(_product(price: 64000).effectivePrice, 64000);
    });

    test('harga diskon ikut tersimpan pada favorit', () {
      final restored = MarketplaceProduct.fromJson(
        _product(price: 80000, discountPrice: 64000).toJson(),
      );
      expect(restored.discountPrice, 64000);
      expect(restored.discountPercent, 20);
    });

    testWidgets('kartu menampilkan lencana dan harga coret', (tester) async {
      await _pumpGrid(tester, 390, 844, [
        _product(price: 80000, discountPrice: 64000),
      ]);

      expect(find.text('-20%'), findsOneWidget);
      // Yang dicoret adalah harga normal; yang besar adalah yang dibayar.
      expect(find.text('Rp64.000'), findsOneWidget);

      final struck = tester.widget<Text>(find.text('Rp80.000'));
      expect(struck.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('produk tanpa diskon tidak menampilkan lencana', (
      tester,
    ) async {
      await _pumpGrid(tester, 390, 844, [_product()]);
      expect(find.textContaining('%'), findsNothing);
    });

    for (final scale in _textScales) {
      testWidgets('kartu diskon tidak meluber pada 320dp text scale $scale', (
        tester,
      ) async {
        await _pumpGrid(tester, 320, 568, [
          _product(price: 80000, discountPrice: 64000),
        ], textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Baris filter kategori', () {
    for (final (label, w, h) in _sizes) {
      testWidgets('tidak overflow pada $label', (tester) async {
        await _pumpFilterRow(tester, w, h);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('tidak overflow pada 320dp text scale ${scale}x', (
        tester,
      ) async {
        await _pumpFilterRow(tester, 320, 568, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('menampilkan Semua lebih dulu, lalu kategori dari API', (
      tester,
    ) async {
      await _pumpFilterRow(tester, 390, 844);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Minuman'), findsOneWidget);
      expect(find.text('Cemilan'), findsOneWidget);
    });

    testWidgets('pilihan aktif ditandai selected untuk pembaca layar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpFilterRow(tester, 390, 844);

      final node = tester.getSemantics(find.text('Semua'));
      expect(node.label, 'Semua');
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
      handle.dispose();
    });

    // Ukurannya dikunci: kedua baris filter duduk di ATAS katalog, dan kartu
    // yang terlalu besar memakan layar sebelum satu produk pun terlihat.
    testWidgets('kartu filter berukuran ringkas', (tester) async {
      await _pumpFilterRow(tester, 390, 844);

      final card = tester.getSize(find.byType(FilterOptionCard).first);
      expect(card.width, 80);
      expect(card.height, 88);
    });

    testWidgets('tinggi baris mengikuti tinggi kartunya', (tester) async {
      await _pumpFilterRow(tester, 390, 844);

      final card = tester.getSize(find.byType(FilterOptionCard).first);
      final row = tester.getSize(find.byType(ListView));
      // Baris tidak boleh menyisakan ruang kosong di bawah kartu.
      expect(row.height, card.height);
    });

    test('setiap kategori mendapat aset gambar yang sesuai', () {
      expect(categoryImageAsset('Kategori Baru'), endsWith('/all.webp'));
      expect(categoryImageAsset('Minuman'), endsWith('/drinks.webp'));
      expect(categoryImageAsset('Bahan Pokok'), endsWith('/staples.webp'));
      expect(categoryImageAsset('Cemilan'), endsWith('/snacks.webp'));
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
