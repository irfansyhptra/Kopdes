@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/discovery/domain/discovery.dart';
import 'package:kopdes/features/koperasi/presentation/providers/koperasi_provider.dart';
import 'package:kopdes/features/location/domain/user_location.dart';
import 'package:kopdes/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:kopdes/features/marketplace/data/marketplace_repository.dart';
import 'package:kopdes/features/marketplace/domain/marketplace.dart';
import 'package:kopdes/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:kopdes/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:kopdes/features/product/domain/entities/category.dart';
import 'package:kopdes/features/product/presentation/providers/product_provider.dart';

/// Tangkapan layar halaman Marketplace pada setiap ukuran yang wajib didukung.
///
/// Bukan uji regresi: berkas ini dilewati pada `flutter test` biasa dan hanya
/// berjalan saat diminta, karena hasilnya bergantung pada versi Flutter dan
/// mesin yang merendernya — golden semacam itu akan merah di mesin lain tanpa
/// ada yang rusak.
///
///     flutter test --update-goldens --tags screenshot \
///       test/marketplace_screenshot_test.dart
///
/// Datanya disuntik lewat provider, bukan diambil dari API: uji widget tidak
/// punya jaringan. Bentuk datanya tetap `MarketplaceProduct` yang sama dengan
/// yang dikirim backend.
const _sizes = <(String, double, double)>[
  ('320x568', 320, 568),
  ('360x800', 360, 800),
  ('390x844', 390, 844),
  ('430x932', 430, 932),
  ('600x960', 600, 960),
  ('768x1024', 768, 1024),
  ('1024x1366', 1024, 1366),
];

MarketplaceProduct _p(
  String id,
  String name,
  String seller,
  double price, {
  bool isUmkm = false,
  double? discountPrice,
  double rating = 4.8,
  int ratingCount = 128,
}) => MarketplaceProduct(
  id: id,
  name: name,
  price: price,
  discountPrice: discountPrice,
  stock: 12,
  categoryId: 'c1',
  sellerName: seller,
  isUmkm: isUmkm,
  ratingAverage: rating,
  ratingCount: ratingCount,
);

final _products = [
  _p('1', 'Beras Premium 5 kg', 'Kopdes Lamteh', 64000, discountPrice: 80000),
  _p(
    '2',
    'Minyak Goreng 2 L',
    'Kopdes Lambhuk',
    34000,
    discountPrice: 40000,
    rating: 4.7,
    ratingCount: 96,
  ),
  _p(
    '3',
    'Kue Adee',
    'Dapur Kak Nur',
    18000,
    isUmkm: true,
    rating: 4.9,
    ratingCount: 54,
  ),
  _p(
    '4',
    'Kopi Arabika Gayo',
    'Kopi Lamteh',
    85000,
    isUmkm: true,
    ratingCount: 78,
  ),
];

const _categories = [
  Category(id: 'f1', name: 'Makanan', group: 'FOOD'),
  Category(id: 'f2', name: 'Cemilan', group: 'FOOD'),
  Category(id: 'f3', name: 'Minuman', group: 'FOOD'),
  Category(id: 'r1', name: 'Bahan Pokok'),
  Category(id: 'r2', name: 'Peralatan Rumah'),
  Category(id: 'r3', name: 'Kesehatan & Kecantikan'),
  Category(id: 'r4', name: 'Pakaian'),
];

/// Roboto dari cache Flutter. Tanpa ini teks dirender sebagai kotak Ahem dan
/// tangkapan layarnya tidak bisa dibaca siapa pun.
Future<void> _loadFonts() async {
  // flutter_tester berjalan dari bin/cache/artifacts/engine/<platform>/,
  // jadi jalurnya dinaiki sampai bertemu bin/cache — bukan jumlah `parent`
  // tetap yang ikut berubah tiap versi Flutter.
  Directory? dir;
  for (var d = File(Platform.resolvedExecutable).parent; ; d = d.parent) {
    final candidate = Directory('${d.path}/artifacts/material_fonts');
    if (candidate.existsSync()) {
      dir = candidate;
      break;
    }
    if (d.path == d.parent.path) break;
  }
  final fonts = dir;
  if (fonts == null) return;

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var found = false;
    for (final name in files) {
      final file = File('${fonts.path}/$name');
      if (!file.existsSync()) continue;
      found = true;
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    if (found) await loader.load();
  }

  const roboto = ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'];
  // Roboto ikut didaftarkan dengan nama keluarga font aplikasi: berkas
  // "Plus Jakarta Sans" tidak ada di mesin uji, dan tanpa pemetaan ini
  // seluruh teks dirender sebagai kotak Ahem.
  await load(AppTypography.fontFamily, roboto);
  await load('Roboto', roboto);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(_loadFonts);

  for (final (label, width, height) in _sizes) {
    testWidgets('Marketplace $label', (tester) async {
      tester.view.physicalSize = Size(width * 2, height * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoriteProductsProvider.overrideWith(
              (ref) => FavoriteNotifier(null),
            ),
            // Lokasi berasal dari cache Isar, yang tidak dibuka di uji
            // widget — disuntik langsung supaya baris lokasi ikut terlihat.
            userCoordinatesProvider.overrideWith(
              (ref) => UserLocation(
                latitude: 5.5306,
                longitude: 95.3197,
                label: 'Desa Lamteh, Banda Aceh',
                isManual: true,
                capturedAt: DateTime(2026, 9, 23),
              ),
            ),
            categoriesProvider.overrideWith((ref) async => _categories),
            bannersProvider.overrideWith(
              (ref) async => const <PromoBanner>[
                PromoBanner(
                  id: 'b1',
                  badge: 'PROMO HARI INI',
                  title: 'Belanja Hemat di',
                  highlight: 'KMP Mitra',
                  description:
                      'Produk Kopdes dan UMKM pilihan untuk kebutuhan keluarga',
                  ctaLabel: 'Belanja Sekarang',
                  ctaRoute: '/products',
                ),
              ],
            ),
            marketplaceProductsProvider.overrideWith(
              (ref) => _StaticListNotifier(_products),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MarketplaceScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(MarketplaceScreen),
        matchesGoldenFile('goldens/marketplace_$label.png'),
      );
    });
  }
}

/// Daftar produk tetap: menggantikan notifier sungguhan yang akan memanggil
/// API begitu dibuat.
class _StaticListNotifier extends MarketplaceListNotifier {
  _StaticListNotifier(List<MarketplaceProduct> items)
    : super(_NoRepository(), const MarketplaceFilter(), null) {
    state = AsyncValue.data(
      MarketplaceListState(items: items, total: items.length),
    );
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  @override
  Future<void> loadMore() async {}
}

class _NoRepository implements MarketplaceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Tangkapan layar tidak memanggil jaringan.');
}
