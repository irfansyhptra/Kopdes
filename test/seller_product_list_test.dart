import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/network/paginated.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/data/models/product_category_model.dart';
import 'package:kopdes/features/umkm/data/models/product_model.dart';
import 'package:kopdes/features/umkm/data/models/seller_product_page.dart';
import 'package:kopdes/features/umkm/data/stock_live_repository.dart';
import 'package:kopdes/features/umkm/domain/repositories/inventory_repository.dart';
import 'package:kopdes/features/umkm/domain/repositories/product_repository.dart';
import 'package:kopdes/features/umkm/domain/repositories/seller_repository.dart';
import 'package:kopdes/features/umkm/presentation/controllers/product_controller.dart';
import 'package:kopdes/features/umkm/presentation/controllers/providers.dart';
import 'package:kopdes/features/umkm/presentation/screens/product_screen.dart';
import 'package:kopdes/features/umkm/presentation/widgets/seller_product_list_ui.dart';
import 'package:kopdes/features/umkm/presentation/widgets/stock_adjust_sheet.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';

const _cat = ProductCategoryModel(id: 'c1', name: 'Minuman', productCount: 3);

ProductModel _p(
  String id, {
  int stock = 20,
  String name = 'Air Mineral 600 ml',
  bool active = true,
}) => ProductModel(
  id: id,
  name: name,
  description: '',
  price: 3500,
  stock: stock,
  categoryId: 'c1',
  category: _cat,
  images: const [],
  isActive: active,
);

/// Ambang sengaja BUKAN 5: membuktikan layar mengikuti angka dari server.
const _threshold = 10;

class _FakeProducts implements ProductRepository {
  List<ProductModel> all;
  Object? failWith;
  final calls = <Map<String, Object?>>[];

  _FakeProducts(this.all);

  @override
  Future<SellerProductPage> getProducts({
    String? search,
    String? categoryId,
    StockLevel? stockLevel,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add({'search': search, 'level': stockLevel, 'page': page});
    if (failWith != null) throw failWith!;
    final base = all
        .where(
          (p) =>
              search == null ||
              p.name.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    final filtered = base
        .where(
          (p) =>
              stockLevel == null ||
              StockLevel.of(p.stock, _threshold) == stockLevel,
        )
        .toList();
    final start = (page - 1) * limit;
    final items = filtered.skip(start).take(limit).toList();
    int count(StockLevel l) =>
        base.where((p) => StockLevel.of(p.stock, _threshold) == l).length;
    return SellerProductPage(
      page: Paginated(
        items: items,
        page: page,
        totalPages: (filtered.length / limit).ceil().clamp(1, 999),
        total: filtered.length,
      ),
      summary: StockSummary(
        safe: count(StockLevel.safe),
        low: count(StockLevel.low),
        out: count(StockLevel.out),
      ),
      lowStockThreshold: _threshold,
    );
  }

  @override
  Future<List<ProductCategoryModel>> getStoreCategories() async => [_cat];

  @override
  Future<void> deleteProduct(String id) async =>
      all = all.where((p) => p.id != id).toList();

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeInventory implements InventoryRepository {
  final _FakeProducts products;
  final adjustments = <(String, int, String)>[];

  _FakeInventory(this.products);

  @override
  Future<int> adjustStock(
    String id,
    int delta, {
    required String reason,
  }) async {
    adjustments.add((id, delta, reason));
    final p = products.all.firstWhere((p) => p.id == id);
    final next = p.stock + delta;
    if (next < 0) throw Exception('Stok tidak mencukupi');
    products.all = [
      for (final x in products.all) x.id == id ? x.copyWith(stock: next) : x,
    ];
    return next;
  }
}

class _QuietLive extends StockLiveRepository {
  _QuietLive() : super(Dio());

  @override
  Future<StockFeedChunk> fetch({String? since, int limit = 50}) async =>
      const StockFeedChunk(movements: [], cursor: 't', hasMore: false);
}

class _NoDashboard implements SellerRepository {
  @override
  dynamic noSuchMethod(Invocation i) => Future<Never>.error('tidak dipakai');
}

Future<_FakeProducts> _pumpScreen(
  WidgetTester tester,
  List<ProductModel> products, {
  double width = 390,
  double textScale = 1.0,
  _FakeProducts? repo,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final fake = repo ?? _FakeProducts(products);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(fake),
        inventoryRepositoryProvider.overrideWithValue(_FakeInventory(fake)),
        stockLiveRepositoryProvider.overrideWithValue(_QuietLive()),
        sellerRepositoryProvider.overrideWithValue(_NoDashboard()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const ProductScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return fake;
}

/// Lepas layar supaya pemantauan stok berhenti dan tidak meninggalkan timer.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('aturan stok', () {
    test('status mengikuti ambang dari server', () {
      expect(StockLevel.of(0, _threshold), StockLevel.out);
      expect(StockLevel.of(1, _threshold), StockLevel.low);
      expect(StockLevel.of(_threshold, _threshold), StockLevel.low);
      expect(StockLevel.of(_threshold + 1, _threshold), StockLevel.safe);
      expect(StockLevel.of(7, 5), StockLevel.safe);
    });

    test('ringkasan berpindah status tanpa memuat ulang', () {
      const s = StockSummary(safe: 2, low: 1, out: 1);
      final moved = s.move(StockLevel.low, StockLevel.safe);
      expect((moved.safe, moved.low, moved.out, moved.total), (3, 0, 1, 4));
      final gone = s.remove(StockLevel.out);
      expect(gone.total, 3);
    });

    test('ambang ikut respons; respons lama jatuh ke aturan backend', () {
      expect(
        SellerProductPage.fromJson({
          'products': [],
          'lowStockThreshold': 8,
        }).lowStockThreshold,
        8,
      );
      expect(SellerProductPage.fromJson({'products': []}).lowStockThreshold, 5);
    });
  });

  group('validasi atur stok', () {
    String? v(String raw, StockDirection d, int stock) =>
        validateStockStep(raw: raw, direction: d, currentStock: stock);

    test('angka harus bulat, minimal 1, dan wajar', () {
      expect(v('', StockDirection.add, 5), isNotNull);
      expect(v('0', StockDirection.add, 5), isNotNull);
      expect(v('abc', StockDirection.add, 5), isNotNull);
      expect(v('100000', StockDirection.add, 5), isNotNull);
      expect(v('3', StockDirection.add, 5), isNull);
    });

    test('mengurangi tidak boleh membuat stok negatif', () {
      expect(v('5', StockDirection.reduce, 5), isNull);
      expect(v('6', StockDirection.reduce, 5), contains('Stok hanya 5'));
      expect(v('1', StockDirection.reduce, 0), contains('habis'));
    });
  });

  group('tata letak baris produk', () {
    const widths = <double>[320, 360, 390, 430, 600, 768];
    const scales = <double>[1.0, 1.3, 1.5, 2.0];

    for (final w in widths) {
      for (final s in scales) {
        testWidgets('tidak meluber ${w.toInt()}dp ${s}x', (tester) async {
          tester.view.physicalSize = Size(w, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(s)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      children: [
                        CategoryFilterBar(
                          categories: const [_cat],
                          selectedId: '',
                          onSelect: (_) {},
                          advancedActive: true,
                          onAdvanced: () {},
                        ),
                        const StockSummaryLine(
                          summary: StockSummary(safe: 120, low: 14, out: 3),
                          activeLevel: StockLevel.low,
                        ),
                        for (final p in [
                          _p('a'),
                          _p(
                            'b',
                            stock: 0,
                            active: false,
                            name:
                                'Keripik Pisang Kepok Rasa Balado Pedas Manis '
                                'Kemasan Keluarga 1 Kilogram Edisi Lebaran',
                          ),
                          _p('c', stock: 123456),
                        ])
                          SellerProductRow(
                            product: p,
                            level: StockLevel.of(p.stock, _threshold),
                            onTap: () {},
                            onAdjustStock: () {},
                            onAction: (_) {},
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('area sentuh "Atur stok" dan menu ≥44', (tester) async {
      for (final w in [320.0, 430.0]) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: SellerProductRow(
                  product: _p('a'),
                  level: StockLevel.safe,
                  onTap: () {},
                  onAdjustStock: () {},
                  onAction: (_) {},
                ),
              ),
            ),
          ),
        );
        final adjust = find
            .ancestor(
              of: find.text('Atur stok'),
              matching: find.byType(ApplePressable),
            )
            .first;
        expect(tester.getSize(adjust).height, greaterThanOrEqualTo(44));
        expect(tester.getSize(adjust).width, greaterThanOrEqualTo(44));
        final menu = find.byType(PopupMenuButton<SellerProductAction>);
        expect(tester.getSize(menu).height, greaterThanOrEqualTo(44));
      }
      tester.view.reset();
    });

    testWidgets('status disebut dengan kata, termasuk nonaktif', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SellerProductRow(
              product: _p('a', stock: 0, active: false),
              level: StockLevel.out,
              onTap: () {},
              onAdjustStock: () {},
              onAction: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Stok 0 · Habis · Nonaktif'), findsOneWidget);
      // Tanpa foto: placeholder netral, bukan gambar lain.
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('daftar berhalaman', () {
    test(
      'muat lebih banyak tidak menggandakan & tidak meminta dobel',
      () async {
        final repo = _FakeProducts([for (var i = 0; i < 45; i++) _p('p$i')]);
        final n = SellerProductListNotifier(repo, const ProductSearchQuery());
        await Future<void>.delayed(Duration.zero);
        expect(n.state.value!.items, hasLength(20));

        // Dua panggilan beruntun = satu permintaan.
        await Future.wait([n.loadMore(), n.loadMore()]);
        expect(repo.calls.where((c) => c['page'] == 2), hasLength(1));
        await n.loadMore();
        final ids = n.state.value!.items.map((p) => p.id).toList();
        expect(ids, hasLength(45));
        expect(ids.toSet(), hasLength(45));
        expect(n.state.value!.hasMore, isFalse);
        n.dispose();
      },
    );

    test(
      'stok berubah → hanya baris itu & ringkasannya yang berubah',
      () async {
        final repo = _FakeProducts([_p('a', stock: 20), _p('b', stock: 3)]);
        final n = SellerProductListNotifier(repo, const ProductSearchQuery());
        await Future<void>.delayed(Duration.zero);
        final callsBefore = repo.calls.length;

        n.applyStock('b', 15);
        final s = n.state.value!;
        expect(s.items.firstWhere((p) => p.id == 'b').stock, 15);
        expect((s.summary.safe, s.summary.low), (2, 0));
        expect(repo.calls.length, callsBefore, reason: 'tanpa muat ulang');

        n.remove('a');
        expect(n.state.value!.items.map((p) => p.id), ['b']);
        expect(n.state.value!.summary.total, 1);
        n.dispose();
      },
    );
  });

  group('layar produk', () {
    testWidgets('ringkasan, baris, dan filter dikirim ke server', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [
        _p('a', stock: 200),
        _p('b', stock: 40, name: 'Roti Tawar'),
        _p('c', stock: 4, name: 'Sabun Mandi'),
        _p('d', stock: 0, name: 'Gula Pasir'),
      ]);

      expect(find.textContaining('4 produk'), findsWidgets);
      expect(find.textContaining('2 aman'), findsOneWidget);
      expect(find.textContaining('1 stok menipis'), findsOneWidget);
      expect(find.textContaining('1 habis'), findsOneWidget);
      expect(find.text('Stok 4 · Menipis'), findsOneWidget);
      expect(find.text('Belum ada perubahan'), findsOneWidget);

      // Filter lanjutan → "Menipis" → permintaan baru dengan stockStatus.
      await tester.tap(find.bySemanticsLabel('Filter lanjutan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menipis').last);
      await tester.pumpAndSettle();
      expect(repo.calls.last['level'], StockLevel.low);
      expect(find.text('Sabun Mandi'), findsOneWidget);
      expect(find.text('Roti Tawar'), findsNothing);
      expect(find.text('Hanya menipis'), findsOneWidget);

      await _unmount(tester);
    });

    testWidgets('pencarian tanpa hasil → pesan + hapus filter', (tester) async {
      final repo = await _pumpScreen(tester, [_p('a')]);
      await tester.enterText(find.byType(TextField), 'kopi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(repo.calls.last['search'], 'kopi');
      expect(find.text('Tidak Ada yang Cocok'), findsOneWidget);

      await tester.tap(find.text('Hapus Pencarian & Filter'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Air Mineral 600 ml'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('toko kosong → "Tambah Produk"', (tester) async {
      await _pumpScreen(tester, []);
      expect(find.text('Belum Ada Produk'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Tambah Produk'),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('API gagal → "Coba Lagi" memuat ulang', (tester) async {
      final repo = _FakeProducts([_p('a')])
        ..failWith = DioException(
          requestOptions: RequestOptions(path: '/seller/products'),
          type: DioExceptionType.connectionError,
        );
      await _pumpScreen(tester, const [], repo: repo);
      expect(find.text('Produk Belum Termuat'), findsOneWidget);

      repo.failWith = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Air Mineral 600 ml'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('atur stok: tersimpan di server, baris & ringkasan menyusul', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [_p('a', stock: 4)]);
      expect(find.textContaining('1 stok menipis'), findsOneWidget);
      final loadsBefore = repo.calls.length;

      await tester.tap(find.text('Atur stok'));
      await tester.pumpAndSettle();
      expect(find.text('Atur Stok'), findsOneWidget);

      // Belum memilih alasan → tidak tersimpan, dan diberi tahu kenapa.
      await tester.enterText(find.byType(TextField).last, '10');
      await tester.pump();
      await tester.tap(find.text('Simpan Perubahan Stok'));
      await tester.pump();
      expect(find.textContaining('Pilih alasannya'), findsOneWidget);

      await tester.tap(find.text('Restok dari pemasok'));
      await tester.pump();
      expect(find.textContaining('→ '), findsOneWidget);
      await tester.tap(find.text('Simpan Perubahan Stok'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Stok Tersimpan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Stok 14 · Aman'), findsOneWidget);
      expect(find.textContaining('1 aman'), findsOneWidget);
      expect(repo.calls.length, loadsBefore, reason: 'tanpa memuat ulang');
      await _unmount(tester);
    });

    testWidgets('tidak meluber pada lebar ponsel & teks besar', (tester) async {
      for (final w in [320.0, 360.0, 390.0, 430.0, 768.0]) {
        for (final s in [1.0, 2.0]) {
          await _pumpScreen(
            tester,
            [
              _p('a'),
              _p(
                'b',
                stock: 2,
                name: 'Nama Produk yang Sangat Panjang Sekali untuk Diuji',
              ),
            ],
            width: w,
            textScale: s,
          );
          expect(tester.takeException(), isNull, reason: '$w dp ${s}x');
          await _unmount(tester);
        }
      }
    });
  });
}
