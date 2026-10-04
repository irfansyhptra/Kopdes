import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/network/paginated.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/data/models/product_category_model.dart';
import 'package:kopdes/features/umkm/data/models/product_image_model.dart';
import 'package:kopdes/features/umkm/data/models/product_model.dart';
import 'package:kopdes/features/umkm/data/models/seller_product_page.dart';
import 'package:kopdes/features/umkm/data/product_draft_store.dart';
import 'package:kopdes/features/umkm/domain/product_rules.dart';
import 'package:kopdes/features/umkm/domain/repositories/product_repository.dart';
import 'package:kopdes/features/umkm/domain/repositories/seller_repository.dart';
import 'package:kopdes/features/umkm/presentation/controllers/product_form_controller.dart';
import 'package:kopdes/features/umkm/presentation/controllers/providers.dart';
import 'package:kopdes/features/umkm/presentation/screens/product_form_screen.dart';
import 'package:kopdes/features/umkm/presentation/widgets/product_form_ui.dart';

const _kopi = ProductCategoryModel(id: 'c-kopi', name: 'Kopi');
const _makanan = ProductCategoryModel(id: 'c-makan', name: 'Makanan');

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/seller/products'),
  type: DioExceptionType.connectionError,
);

class _FakeRepo implements ProductRepository {
  final creates = <Map<String, Object?>>[];
  final updates = <Map<String, Object?>>[];
  final uploads = <String>[];

  /// Unggahan ke-N (mulai 1) gagal sekali.
  int? failUploadAt;
  Object? failCreate;

  /// Bila diisi, createProduct menunggu sampai ini selesai.
  Completer<void>? holdCreate;
  ProductModel? existing;

  @override
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  }) async {
    creates.add({
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'images': images,
    });
    if (holdCreate != null) await holdCreate!.future;
    if (failCreate != null) throw failCreate!;
    return ProductModel(
      id: 'new-1',
      name: name,
      description: description,
      price: price,
      stock: stock,
      categoryId: categoryId,
      images: const [],
    );
  }

  @override
  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  }) async {
    updates.add({'id': id, 'name': name, 'stock': stock, 'price': price});
    return existing ??
        ProductModel(
          id: id,
          name: name ?? '',
          description: description ?? '',
          price: price ?? 0,
          stock: 0,
          categoryId: categoryId ?? '',
          images: const [],
        );
  }

  @override
  Future<void> addProductImage(String id, String path) async {
    uploads.add(path);
    if (failUploadAt == uploads.length) {
      failUploadAt = null;
      throw _offline();
    }
  }

  @override
  Future<ProductModel> getProduct(String id) async => existing!;

  @override
  Future<List<ProductCategoryModel>> getCategories() async => [_kopi, _makanan];

  @override
  Future<List<ProductCategoryModel>> getStoreCategories() async => [_kopi];

  @override
  Future<SellerProductPage> getProducts({
    String? search,
    String? categoryId,
    StockLevel? stockLevel,
    int page = 1,
    int limit = 20,
  }) async => const SellerProductPage(
    page: Paginated(items: [], page: 1, totalPages: 1, total: 0),
    summary: StockSummary(),
    lowStockThreshold: 5,
  );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Draf di memori — berkas sungguhan diuji terpisah di bawah.
class _MemDrafts extends ProductDraftStore {
  ProductDraft? stored;
  _MemDrafts([this.stored]) : super(ownerId: 'test');

  @override
  Future<ProductDraft?> load() async => stored;

  @override
  Future<ProductDraft> save(ProductDraft draft) async => stored = draft;

  @override
  Future<void> clear() async => stored = null;
}

class _FakePicker implements ProductPhotoPicker {
  List<String> next = const [];

  @override
  Future<PickedPhotos> pick(PhotoSource source, {required int max}) async =>
      PickedPhotos(next.take(max).toList());
}

class _NoDashboard implements SellerRepository {
  @override
  dynamic noSuchMethod(Invocation i) => Future<Never>.error('tidak dipakai');
}

ProviderContainer _container(_FakeRepo repo, ProductDraftStore drafts) {
  final c = ProviderContainer(
    overrides: [
      productRepositoryProvider.overrideWithValue(repo),
      productDraftStoreProvider.overrideWithValue(drafts),
      sellerRepositoryProvider.overrideWithValue(_NoDashboard()),
    ],
  );
  addTearDown(c.dispose);
  // Provider form bersifat autoDispose: tanpa pendengar, ia dibuang di
  // antara dua `read` dan pemuatan async-nya tidak pernah mendarat.
  for (final id in [null, 'p1']) {
    c.listen(productFormProvider(id), (_, __) {});
  }
  return c;
}

void _fill(ProductFormNotifier f, {List<String> photos = const []}) {
  f
    ..setName('Kopi Arabika Gayo 250 g')
    ..setCategory(_kopi.id)
    ..setPrice('65000')
    ..setStock('12')
    ..addPhotos(photos);
}

void main() {
  group('aturan isian', () {
    test('nama, kategori, deskripsi', () {
      expect(ProductRules.name(''), contains('wajib'));
      expect(ProductRules.name('  ab '), contains('minimal'));
      expect(ProductRules.name('x' * 121), contains('maksimal'));
      expect(ProductRules.name('Kopi Gayo'), isNull);
      expect(ProductRules.category(null), isNotNull);
      expect(ProductRules.description('x' * 501), isNotNull);
      expect(ProductRules.description(''), isNull, reason: 'opsional');
    });

    test('harga dan stok', () {
      expect(ProductRules.price(''), contains('wajib'));
      expect(ProductRules.price('0'), contains('minimal'));
      expect(ProductRules.price('99999999999'), contains('terlalu besar'));
      expect(ProductRules.price('15000'), isNull);
      expect(ProductRules.stock(''), contains('wajib'));
      expect(ProductRules.stock('0'), isNull, reason: 'stok 0 sah');
      expect(ProductRules.stock('10000000'), contains('maksimal'));
    });

    test('format rupiah saat mengetik, nilai tetap angka polos', () {
      final f = ThousandsInputFormatter();
      String type(String t) => f
          .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t))
          .text;
      expect(type('15000'), '15.000');
      expect(type('1500000'), '1.500.000');
      expect(type('abc'), '');
      expect(ThousandsInputFormatter.digitsOf('015.000'), '15000');
    });
  });

  group('form produk baru', () {
    test(
      'Lanjut memeriksa kolom wajib tahap aktif; kembali tidak menghapus',
      () {
        final c = _container(_FakeRepo(), _MemDrafts());
        final f = c.read(productFormProvider(null).notifier);

        expect(f.next(), isFalse);
        final errors = c.read(productFormProvider(null)).visibleErrors(0);
        expect(errors.keys, containsAll(['name', 'category']));

        f
          ..setName('Kopi Gayo')
          ..setCategory(_kopi.id);
        expect(f.next(), isTrue);
        expect(c.read(productFormProvider(null)).step, 1);

        expect(f.next(), isFalse, reason: 'harga & stok kosong');
        f.back();
        expect(c.read(productFormProvider(null)).data.name, 'Kopi Gayo');
      },
    );

    test('kirim dua kali beruntun → satu produk', () async {
      final repo = _FakeRepo()..holdCreate = Completer();
      final c = _container(repo, _MemDrafts());
      final f = c.read(productFormProvider(null).notifier);
      _fill(f);

      final first = f.submit();
      final second = await f.submit();
      expect(second, isA<SubmitInvalid>(), reason: 'ditolak penjaga');
      repo.holdCreate!.complete();
      expect(await first, isA<SubmitSucceeded>());
      expect(repo.creates, hasLength(1));
      expect(repo.creates.single['images'], isNull);
      expect(repo.creates.single['price'], 65000);
      expect(repo.creates.single['stock'], 12);
    });

    test(
      'foto gagal → produk tidak dibuat ulang, sisa foto diulang berurutan',
      () async {
        final repo = _FakeRepo()..failUploadAt = 2;
        final c = _container(repo, _MemDrafts());
        final f = c.read(productFormProvider(null).notifier);
        _fill(f, photos: ['/a.jpg', '/b.jpg', '/c.jpg']);

        final r1 = await f.submit();
        expect(r1, isA<SubmitPhotosPending>());
        expect((r1 as SubmitPhotosPending).remaining, 2);
        // Berhenti di kegagalan pertama: c tidak boleh mendahului b.
        expect(repo.uploads, ['/a.jpg', '/b.jpg']);
        final s = c.read(productFormProvider(null));
        expect(s.awaitingPhotos, isTrue);
        expect(s.stockLocked, isTrue);
        expect(s.data.photos[1].status, PhotoStatus.failed);

        final r2 = await f.submit();
        expect(r2, isA<SubmitSucceeded>());
        expect(repo.creates, hasLength(1), reason: 'tidak ada produk ganda');
        expect(
          repo.updates.single['stock'],
          isNull,
          reason: 'stok tak ditimpa',
        );
        expect(repo.uploads, ['/a.jpg', '/b.jpg', '/b.jpg', '/c.jpg']);
      },
    );

    test(
      'koneksi putus saat membuat → isian utuh, bisa dikirim ulang',
      () async {
        final repo = _FakeRepo()..failCreate = _offline();
        final drafts = _MemDrafts();
        final c = _container(repo, drafts);
        final f = c.read(productFormProvider(null).notifier);
        _fill(f, photos: ['/a.jpg']);
        await f.saveDraft();

        expect(await f.submit(), isA<SubmitFailed>());
        final s = c.read(productFormProvider(null));
        expect(s.data.name, 'Kopi Arabika Gayo 250 g');
        expect(s.data.photos, hasLength(1));
        expect(s.createdId, isNull);
        expect(drafts.stored, isNotNull, reason: 'draf tidak terbuang');

        repo.failCreate = null;
        expect(await f.submit(), isA<SubmitSucceeded>());
        expect(drafts.stored, isNull, reason: 'draf dibuang setelah terkirim');
      },
    );

    test('draf ditawarkan saat form dibuka lagi, lalu dipulihkan', () async {
      final drafts = _MemDrafts(
        ProductDraft(
          name: 'Keripik',
          categoryId: _makanan.id,
          description: 'Renyah',
          price: '12000',
          stock: '30',
          photos: const ['/d.jpg'],
          savedAt: DateTime(2026, 10, 4, 16, 20),
        ),
      );
      final c = _container(_FakeRepo(), drafts);
      c.read(productFormProvider(null));
      await Future<void>.delayed(Duration.zero);

      expect(c.read(productFormProvider(null)).offeredDraft, isNotNull);
      c.read(productFormProvider(null).notifier).restoreDraft();
      final s = c.read(productFormProvider(null));
      expect(s.data.name, 'Keripik');
      expect(s.data.photos.single.path, '/d.jpg');
      expect(s.isDirty, isFalse);
    });

    test('urutan foto: jadikan utama, geser, hapus, maksimal 5', () {
      final c = _container(_FakeRepo(), _MemDrafts());
      final f = c.read(productFormProvider(null).notifier);
      f.addPhotos(['/1', '/2', '/3', '/4', '/5', '/6']);
      List<String?> paths() => c
          .read(productFormProvider(null))
          .data
          .photos
          .map((p) => p.path)
          .toList();
      expect(paths(), hasLength(5));
      f.makePrimary(2);
      expect(paths().first, '/3');
      f.movePhoto(0, 1);
      expect(paths().take(2), ['/1', '/3']);
      f.removePhoto(0);
      expect(paths(), ['/3', '/2', '/4', '/5']);
    });
  });

  group('form edit', () {
    test('stok dikunci, foto lama tidak bisa dihapus palsu', () async {
      final repo = _FakeRepo()
        ..existing = const ProductModel(
          id: 'p1',
          name: 'Kopi Sanger',
          description: '',
          price: 15000,
          stock: 40,
          categoryId: 'c-kopi',
          images: [
            ProductImageModel(
              id: 'i1',
              url: 'https://x/1.jpg',
              isPrimary: true,
            ),
          ],
        );
      final c = _container(repo, _MemDrafts());
      c.read(productFormProvider('p1'));
      await Future<void>.delayed(Duration.zero);
      final f = c.read(productFormProvider('p1').notifier);

      final s = c.read(productFormProvider('p1'));
      expect(s.data.price, '15000');
      expect(s.stockLocked, isTrue);
      expect(f.canEditPhoto(0), isFalse);
      f.removePhoto(0);
      expect(c.read(productFormProvider('p1')).data.photos, hasLength(1));

      f.setPrice('16000');
      expect(await f.submit(), isA<SubmitSucceeded>());
      expect(repo.updates.single, containsPair('stock', null));
      expect(repo.updates.single, containsPair('price', 16000.0));
      expect(repo.creates, isEmpty);
    });
  });

  group('draf di berkas', () {
    test(
      'foto disalin ke folder draf, draf per akun, bersih saat dibuang',
      () async {
        final root = await Directory.systemTemp.createTemp('draft_test');
        addTearDown(() => root.delete(recursive: true));
        final picked = File('${root.path}/picker_cache.jpg')
          ..writeAsBytesSync([1, 2, 3]);

        final a = ProductDraftStore(ownerId: 'user-a', root: () async => root);
        final b = ProductDraftStore(ownerId: 'user-b', root: () async => root);

        final saved = await a.save(
          ProductDraft(
            name: 'Kopi',
            categoryId: 'c',
            description: '',
            price: '1000',
            stock: '1',
            photos: [picked.path],
            savedAt: DateTime(2026),
          ),
        );
        expect(saved.photos.single, isNot(picked.path));
        expect(File(saved.photos.single).existsSync(), isTrue);

        // Berkas sementara pemilih gambar hilang — draf tetap utuh.
        picked.deleteSync();
        final loaded = await a.load();
        expect(loaded!.name, 'Kopi');
        expect(loaded.photos, hasLength(1));
        expect(await b.load(), isNull, reason: 'akun lain tidak melihatnya');

        await a.clear();
        expect(await a.load(), isNull);
      },
    );
  });

  group('layar', () {
    Future<(ProviderContainer, _FakeRepo, _MemDrafts, GoRouter)> pump(
      WidgetTester tester, {
      double width = 390,
      double scale = 1.0,
      double keyboard = 0,
      _FakeRepo? repo,
      _MemDrafts? drafts,
    }) async {
      tester.view.physicalSize = Size(width, 860);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);

      final r = repo ?? _FakeRepo();
      final d = drafts ?? _MemDrafts();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('daftar produk')),
          GoRoute(path: '/form', builder: (_, __) => const ProductFormScreen()),
        ],
      );
      final c = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(r),
          productDraftStoreProvider.overrideWithValue(d),
          productPhotoPickerProvider.overrideWithValue(_FakePicker()),
          sellerRepositoryProvider.overrideWithValue(_NoDashboard()),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      router.push('/form');
      await tester.pumpAndSettle();
      return (c, r, d, router);
    }

    ProductFormNotifier form(ProviderContainer c) =>
        c.read(productFormProvider(null).notifier);

    testWidgets('form kosong → galat spesifik, tetap di tahap 1', (t) async {
      await pump(t);
      expect(find.text('Detail produk'), findsOneWidget);
      await t.tap(find.text('Lanjut'));
      await t.pumpAndSettle();
      expect(find.text('Nama produk wajib diisi.'), findsOneWidget);
      expect(find.text('Pilih kategori produknya.'), findsOneWidget);
    });

    testWidgets(
      'alur penuh: kategori dari data, rupiah terformat, Ubah kembali',
      (t) async {
        final (c, repo, _, router) = await pump(t);
        await t.enterText(find.byType(TextField).first, 'Kopi Gayo 250 g');
        await t.tap(find.text('Pilih kategori'));
        await t.pumpAndSettle();
        expect(find.text('Makanan'), findsOneWidget, reason: 'dari API');
        await t.tap(find.text('Kopi'));
        await t.pumpAndSettle();
        await t.tap(find.text('Lanjut'));
        await t.pumpAndSettle();

        // Tahap 2: harga tidak valid lalu valid.
        await t.tap(find.text('Lanjut'));
        await t.pumpAndSettle();
        expect(find.text('Harga jual wajib diisi.'), findsOneWidget);
        await t.enterText(find.byType(TextField).at(0), '15000');
        await t.pump();
        expect(find.text('15.000'), findsOneWidget);
        expect(c.read(productFormProvider(null)).data.price, '15000');
        await t.enterText(find.byType(TextField).at(1), '8');
        await t.tap(find.text('Lanjut'));
        await t.pumpAndSettle();

        // Tahap 3.
        expect(find.text('Rp15.000'), findsOneWidget);
        expect(find.text('Tanpa deskripsi'), findsOneWidget);
        expect(find.text('Kirim Produk'), findsOneWidget);
        await t.tap(find.text('Ubah').first);
        await t.pumpAndSettle();
        expect(
          find.text('Kopi Gayo 250 g'),
          findsOneWidget,
          reason: 'isian utuh',
        );

        // Kirim.
        form(c).goTo(0);
        for (var i = 0; i < 2; i++) {
          await t.tap(find.text('Lanjut'));
          await t.pumpAndSettle();
        }
        await t.tap(find.text('Kirim Produk'));
        await t.pump();
        await t.tap(find.text('Kirim Produk'), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('Produk Terkirim'), findsOneWidget);
        await t.pump(const Duration(seconds: 3));
        await t.pumpAndSettle();
        expect(repo.creates, hasLength(1), reason: 'ketukan kedua diabaikan');
        expect(find.text('daftar produk'), findsOneWidget, reason: 'kembali');
        expect(router.state.uri.path, '/');
      },
    );

    testWidgets('kembali dengan isian → tawaran; Simpan Draf menyimpan', (
      t,
    ) async {
      final (c, _, drafts, _) = await pump(t);
      await t.enterText(find.byType(TextField).first, 'Keripik');
      await t.pump();

      await t.tap(find.bySemanticsLabel('Kembali'));
      await t.pumpAndSettle();
      expect(find.text('Lanjut Mengisi'), findsOneWidget);
      expect(find.text('Keluar Tanpa Simpan'), findsOneWidget);
      await t.tap(find.text('Simpan Draf'));
      await t.pumpAndSettle();
      expect(drafts.stored?.name, 'Keripik');
      expect(find.text('daftar produk'), findsOneWidget);
    });

    testWidgets('tahap 2 kembali ke tahap 1 tanpa dialog', (t) async {
      final (c, _, _, _) = await pump(t);
      form(c)
        ..setName('Kopi Gayo')
        ..setCategory(_kopi.id)
        ..next();
      await t.pumpAndSettle();
      expect(find.textContaining('Harga jual'), findsWidgets);
      await t.tap(find.bySemanticsLabel('Kembali'));
      await t.pumpAndSettle();
      expect(find.text('Lanjut Mengisi'), findsNothing);
      expect(find.text('Informasi produk'), findsOneWidget);
    });

    testWidgets('foto gagal diunggah → "Unggah Ulang Foto" & tanda Gagal', (
      t,
    ) async {
      final repo = _FakeRepo()..failUploadAt = 1;
      final (c, _, _, _) = await pump(t, repo: repo);
      _fill(form(c), photos: ['/tidak-ada.jpg']);
      form(c)
        ..next()
        ..next();
      await t.pumpAndSettle();
      await t.tap(find.text('Kirim Produk'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Sebagian Foto Belum Terunggah'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('Unggah Ulang Foto'), findsOneWidget);
      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('keyboard terbuka: tombol tetap di atas keyboard', (t) async {
      await pump(t, keyboard: 320);
      final button = t.getRect(find.widgetWithText(FilledButton, 'Lanjut'));
      expect(button.bottom, lessThanOrEqualTo(860 - 320));
    });

    for (final w in [320.0, 360.0, 390.0, 430.0, 768.0]) {
      for (final s in [1.0, 1.5, 2.0]) {
        testWidgets('tiga tahap tidak meluber ${w.toInt()}dp ${s}x', (t) async {
          final (c, _, _, _) = await pump(t, width: w, scale: s);
          expect(t.takeException(), isNull, reason: 'tahap 1');
          _fill(
            form(c),
            photos: ['/1.jpg', '/2.jpg', '/3.jpg', '/4.jpg', '/5.jpg'],
          );
          form(c)
            ..setName(
              'Keripik Pisang Kepok Rasa Balado Pedas Manis Kemasan '
              'Keluarga Edisi Lebaran',
            )
            ..next();
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: 'tahap 2');
          form(c).next();
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: 'tahap 3');
        });
      }
    }
  });
}
