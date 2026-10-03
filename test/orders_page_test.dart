import 'package:kopdes/features/order/presentation/providers/order_provider.dart';
import 'package:kopdes/features/order/presentation/widgets/order_summary.dart';
import 'package:kopdes/features/order/data/review_repository.dart';
import 'package:kopdes/features/order/data/models/order_model.dart';
import 'package:kopdes/features/order/domain/order_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/order/domain/entities/cart.dart';
import 'package:kopdes/features/order/domain/entities/order.dart';
import 'package:kopdes/features/order/domain/entities/seller_ref.dart';
import 'package:kopdes/features/order/domain/order_status_view.dart';
import 'package:kopdes/features/order/domain/repositories/order_repository.dart';
import 'package:kopdes/features/order/presentation/providers/cart_provider.dart';
import 'package:kopdes/features/order/presentation/providers/orders_page_provider.dart';
import 'package:kopdes/features/order/presentation/widgets/cart_seller_group.dart';
import 'package:kopdes/features/order/presentation/widgets/orders_responsive.dart';
import 'package:kopdes/features/order/presentation/widgets/shopping_summary.dart';
import 'package:kopdes/features/product/domain/entities/product.dart';

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

const _kopdes = SellerRef(
  id: 'k1',
  name: 'Kopdes Merah Putih Lamteh',
  verified: true,
);
const _umkm = SellerRef(
  id: 'u1',
  name: 'Dapur Kak Nur',
  isUmkm: true,
  verified: true,
);

Product _product({
  String id = 'p1',
  String name = 'Beras Premium 5 kg',
  double price = 64000,
  int stock = 25,
}) => Product(
  id: id,
  name: name,
  description: '',
  price: price,
  stock: stock,
  categoryId: 'c1',
  images: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

CartItem _item({
  required String id,
  SellerRef seller = _kopdes,
  String name = 'Beras Premium 5 kg',
  double price = 64000,
  int stock = 25,
  int quantity = 1,
}) => CartItem(
  id: id,
  cartId: 'cart',
  productId: 'prod-$id',
  product: _product(id: 'prod-$id', name: name, price: price, stock: stock),
  quantity: quantity,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  seller: seller,
);

Cart _cart(List<CartItem> items) => Cart(
  id: 'cart',
  userId: 'u',
  items: items,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

/// Keranjang campuran: dua produk Kopdes dan satu produk Mitra UMKM.
final _mixedCart = _cart([
  _item(id: 'a'),
  _item(id: 'b', name: 'Minyak Goreng 2 L', price: 34000),
  _item(id: 'c', seller: _umkm, name: 'Kue Adee', price: 18000, stock: 10),
]);

/// Keranjang palsu yang tidak menyentuh jaringan maupun Isar.
class _StubCartNotifier extends CartNotifier {
  _StubCartNotifier(Cart cart, Ref ref) : super(_NullRepository(), ref) {
    state = AsyncValue.data(cart);
  }

  @override
  Future<void> loadCart() async {}
}

/// Test ini menguji keadaan dan tata letak, bukan jaringan: setiap panggilan
/// repository di sini adalah tanda ada jalur yang tidak seharusnya berjalan.
class _NullRepository implements OrderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Repository tidak dipakai pada test ini');
}

ProviderContainer _container(Cart cart) {
  final container = ProviderContainer(
    overrides: [
      cartProvider.overrideWith((ref) => _StubCartNotifier(cart, ref)),
    ],
  );
  addTearDown(container.dispose);
  // Pilihan menyelaraskan diri lewat ref.listen; membaca providernya sekali
  // sudah cukup untuk memicu sinkronisasi awal.
  container.read(selectedCartItemsProvider);
  return container;
}

void main() {
  _moneyAndPagingTests();

  group('Pilihan produk', () {
    test('semua produk tercentang saat keranjang pertama kali dimuat', () {
      final container = _container(_mixedCart);
      expect(container.read(selectedCartItemsProvider), {'a', 'b', 'c'});
      expect(container.read(allItemsCheckStateProvider), CheckState.all);
    });

    test('melepas satu produk membuat tokonya menjadi sebagian', () {
      final container = _container(_mixedCart);
      container.read(selectedCartItemsProvider.notifier).toggleItem('a');

      expect(
        container.read(sellerGroupCheckStateProvider('k1')),
        CheckState.some,
      );
      // Toko lain tidak ikut terpengaruh.
      expect(
        container.read(sellerGroupCheckStateProvider('u1')),
        CheckState.all,
      );
      expect(container.read(allItemsCheckStateProvider), CheckState.some);
    });

    test('melepas seluruh produk satu toko membuat toko itu kosong', () {
      final container = _container(_mixedCart);
      final notifier = container.read(selectedCartItemsProvider.notifier);
      notifier.unselectSeller(['a', 'b']);

      expect(
        container.read(sellerGroupCheckStateProvider('k1')),
        CheckState.none,
      );
      expect(container.read(allItemsCheckStateProvider), CheckState.some);
    });

    test('mengosongkan semua pilihan mematikan checkout', () {
      final container = _container(_mixedCart);
      container.read(selectedCartItemsProvider.notifier).clearSelection();

      expect(container.read(allItemsCheckStateProvider), CheckState.none);
      expect(container.read(cartSummaryProvider).canCheckout, isFalse);
    });

    test('produk yang hilang dari keranjang dibuang dari pilihan', () {
      final container = _container(_mixedCart);
      container.read(selectedCartItemsProvider.notifier).syncWithCart({
        'a',
        'b',
      });

      expect(container.read(selectedCartItemsProvider), {'a', 'b'});
    });

    // Tanpa penjagaan ini, setiap respons /cart akan mencentang ulang produk
    // yang baru saja sengaja dilepas pengguna.
    test(
      'pilihan yang dilepas tidak tercentang lagi saat cart dimuat ulang',
      () {
        final container = _container(_mixedCart);
        final notifier = container.read(selectedCartItemsProvider.notifier);
        notifier.toggleItem('a');
        notifier.syncWithCart({'a', 'b', 'c'});

        expect(container.read(selectedCartItemsProvider), {'b', 'c'});
      },
    );
  });

  group('Pengelompokan penjual', () {
    test('produk dikelompokkan per toko dengan urutan tetap', () {
      final container = _container(_mixedCart);
      final groups = container.read(cartSellerGroupsProvider);

      expect(groups.length, 2);
      expect(groups.first.seller.name, 'Kopdes Merah Putih Lamteh');
      expect(groups.first.itemIds, ['a', 'b']);
      expect(groups.last.seller.isUmkm, isTrue);
      expect(groups.last.itemIds, ['c']);
    });

    // Tanpa kunci cadangan, tiap produk tanpa relasi penjual akan menjadi
    // grupnya sendiri.
    test('produk tanpa data penjual berkumpul jadi satu grup', () {
      final container = _container(
        _cart([
          _item(id: 'x', seller: const SellerRef()),
          _item(id: 'y', seller: const SellerRef()),
        ]),
      );

      expect(container.read(cartSellerGroupsProvider).length, 1);
    });
  });

  group('Perhitungan total', () {
    test('total hanya menjumlahkan produk yang dipilih', () {
      final container = _container(_mixedCart);
      container.read(selectedCartItemsProvider.notifier).toggleItem('c');

      final summary = container.read(cartSummaryProvider);
      expect(summary.subtotal, 64000 + 34000);
      expect(summary.selectedLines, 2);
      expect(summary.total, 98000);
      // Produk yang tidak dipilih tetap ada di keranjang.
      expect(summary.totalLines, 3);
    });

    test('jumlah barang ikut dikalikan', () {
      final container = _container(_cart([_item(id: 'a', quantity: 3)]));

      final summary = container.read(cartSummaryProvider);
      expect(summary.subtotal, 192000);
      expect(summary.selectedUnits, 3);
      expect(summary.selectedLines, 1);
    });

    test('total memakai rumus subtotal + ongkir - diskon', () {
      const summary = CartSummary(
        subtotal: 116000,
        shipping: 0,
        discount: 5000,
        selectedLines: 3,
      );
      expect(summary.total, 111000);
    });
  });

  group('Status pesanan', () {
    test('status gudang diterjemahkan ke bahasa pemesan', () {
      expect(OrderStatusView.of('OUT_FOR_DELIVERY').label, 'Dalam pengiriman');
      expect(
        OrderStatusView.of('READY_FOR_DELIVERY').label,
        'Siap diambil kurir',
      );
    });

    // Sudah sampai tetapi belum dikonfirmasi masih menunggu tindakan pemesan.
    test('DELIVERED masih dihitung sebagai pesanan berjalan', () {
      expect(OrderStatusView.of('DELIVERED').isActive, isTrue);
      expect(OrderStatusView.of('COMPLETED').isActive, isFalse);
      expect(OrderStatusView.of('CANCELLED').isCancelled, isTrue);
    });

    // Status yang tidak dikenal lebih baik muncul di tab Diproses daripada
    // hilang dari kedua tab.
    test('status tak dikenal tetap muncul sebagai pesanan berjalan', () {
      final view = OrderStatusView.of('SOMETHING_NEW');
      expect(view.isActive, isTrue);
      expect(view.label, 'Something New');
    });

    test('nomor pesanan memakai nomor invoice bila ada', () {
      final order = Order(
        id: 'abcdef1234567890',
        customerId: 'u',
        totalAmount: 111000,
        status: 'PENDING',
        paymentMethod: 'QRIS',
        paymentStatus: 'PENDING',
        deliveryAddressId: 'a1',
        items: const [],
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );
      expect(order.displayNumber, '#ABCDEF12');
    });
  });

  group('OrdersSpec', () {
    test('kolom terpisah baru muncul mulai tablet', () {
      expect(OrdersSpec.fromWidth(320).splitLayout, isFalse);
      expect(OrdersSpec.fromWidth(430).splitLayout, isFalse);
      expect(OrdersSpec.fromWidth(768).splitLayout, isTrue);
      expect(OrdersSpec.fromWidth(1024).splitLayout, isTrue);
    });

    test('padding dan lebar konten mengikuti lebar layar', () {
      expect(OrdersSpec.fromWidth(320).pagePadding, 12);
      expect(OrdersSpec.fromWidth(390).pagePadding, 16);
      expect(OrdersSpec.fromWidth(1024).contentMaxWidth, 1120);
    });

    test('layar pendek memulai ringkasan dalam keadaan terlipat', () {
      expect(OrdersSpec.shouldCollapseSummary(const Size(320, 568)), isTrue);
      expect(OrdersSpec.shouldCollapseSummary(const Size(390, 844)), isFalse);
    });
  });

  group('Tata letak tidak overflow', () {
    for (final (label, w, h) in _sizes) {
      testWidgets('grup keranjang pada $label', (tester) async {
        await _pumpCart(tester, w, h);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in _textScales) {
      testWidgets('grup keranjang pada 320dp text scale ${scale}x', (
        tester,
      ) async {
        await _pumpCart(tester, 320, 568, textScale: scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ringkasan pada 320dp text scale ${scale}x', (tester) async {
        await _pumpSummary(tester, 320, 568, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('nama produk sangat panjang tidak meluber', (tester) async {
      await _pumpCart(
        tester,
        320,
        568,
        cart: _cart([
          _item(
            id: 'long',
            name:
                'Beras Premium Organik Pilihan Petani Desa Lamteh Kemasan '
                'Karung 25 Kilogram Kualitas Ekspor Panen Terbaru',
            seller: const SellerRef(
              id: 'k9',
              name: 'Koperasi Desa Merah Putih Lamteh Ulee Kareng Banda Aceh',
              verified: true,
            ),
          ),
        ]),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('harga sangat besar tidak meluber', (tester) async {
      await _pumpSummary(
        tester,
        320,
        568,
        cart: _cart([_item(id: 'big', price: 999999999, quantity: 9)]),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Isi kartu keranjang', () {
    testWidgets('menampilkan lencana toko, stok, dan harga', (tester) async {
      await _pumpCart(tester, 390, 844);

      expect(find.text('KOPDES'), findsOneWidget);
      expect(find.text('MITRA UMKM'), findsOneWidget);
      expect(find.text('Kopdes Merah Putih Lamteh'), findsOneWidget);
      expect(find.text('Dapur Kak Nur'), findsOneWidget);
      expect(find.text('Stok 25 tersedia'), findsNWidgets(2));
      expect(find.text('Rp64.000'), findsOneWidget);
      expect(find.text('Pilih Semua'), findsNWidgets(2));
    });

    testWidgets('harga yang besar adalah total baris, bukan harga satuan', (
      tester,
    ) async {
      await _pumpCart(
        tester,
        390,
        844,
        cart: _cart([_item(id: 'a', price: 65000, quantity: 3)]),
      );

      // Yang dibayar untuk baris ini, bukan harga satuannya: keranjang berisi
      // 3 × Rp65.000 sempat terbaca "Rp65.000".
      expect(find.text('Rp195.000'), findsOneWidget);
      // Perkaliannya tetap terlihat, sebagai keterangan kecil.
      expect(find.text('Rp65.000 × 3'), findsOneWidget);
    });

    testWidgets('satu barang tidak menampilkan perkalian', (tester) async {
      await _pumpCart(
        tester,
        390,
        844,
        cart: _cart([_item(id: 'a', price: 65000)]),
      );
      expect(find.text('Rp65.000'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('harga ditulis merah, bukan warna teks biasa', (tester) async {
      await _pumpCart(
        tester,
        390,
        844,
        cart: _cart([_item(id: 'a', price: 65000, quantity: 2)]),
      );

      final price = tester.widget<Text>(find.text('Rp130.000'));
      expect(price.style?.color, AppColors.primary);
    });

    testWidgets('stok habis ditandai teks, bukan hanya warna', (tester) async {
      await _pumpCart(
        tester,
        390,
        844,
        cart: _cart([_item(id: 'z', stock: 0)]),
      );
      expect(find.text('Stok habis'), findsOneWidget);
    });
  });

  group('Ringkasan Belanja', () {
    testWidgets('menampilkan subtotal, ongkir, diskon, dan total', (
      tester,
    ) async {
      await _pumpSummary(tester, 390, 844);

      expect(find.text('Subtotal (3 produk)'), findsOneWidget);
      expect(find.text('Rp116.000'), findsNWidgets(2)); // subtotal & total
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Pilih Semua (3 produk)'), findsOneWidget);
      expect(find.text('Checkout (3)'), findsOneWidget);
    });

    testWidgets('terlipat hanya menampilkan total dan checkout', (
      tester,
    ) async {
      await _pumpSummary(tester, 390, 844, expanded: false);

      expect(find.text('Subtotal (3 produk)'), findsNothing);
      expect(find.text('Total Pembayaran'), findsOneWidget);
      expect(find.text('Checkout (3)'), findsOneWidget);
    });

    testWidgets('checkout mati saat tidak ada produk dipilih', (tester) async {
      var tapped = 0;
      final container = _container(_mixedCart);
      container.read(selectedCartItemsProvider.notifier).clearSelection();

      await _pumpWidget(
        tester,
        390,
        844,
        container,
        ShoppingSummaryBody(expanded: true, onCheckout: () => tapped++),
      );

      expect(find.text('Checkout (0)'), findsOneWidget);
      await tester.tap(find.text('Checkout (0)'));
      await tester.pump();
      expect(tapped, 0);
    });
  });
}

// ─────────────────────────────────────────────────────────────
// Pembantu render
// ─────────────────────────────────────────────────────────────

Future<void> _pumpWidget(
  WidgetTester tester,
  double width,
  double height,
  ProviderContainer container,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            backgroundColor: AppColors.surfaceSoft,
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: OrdersSpec.fromWidth(width).pagePadding,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpCart(
  WidgetTester tester,
  double width,
  double height, {
  double textScale = 1.0,
  Cart? cart,
}) async {
  final container = _container(cart ?? _mixedCart);
  final spec = OrdersSpec.fromWidth(width);

  await _pumpWidget(
    tester,
    width,
    height,
    container,
    Column(
      children: [
        for (final group in container.read(cartSellerGroupsProvider))
          CartSellerGroupCard(group: group, spec: spec),
      ],
    ),
    textScale: textScale,
  );
}

Future<void> _pumpSummary(
  WidgetTester tester,
  double width,
  double height, {
  double textScale = 1.0,
  bool expanded = true,
  Cart? cart,
}) async {
  await _pumpWidget(
    tester,
    width,
    height,
    _container(cart ?? _mixedCart),
    ShoppingSummaryBody(expanded: expanded, onCheckout: () {}),
    textScale: textScale,
  );
}

// ─────────────────────────────────────────────────────────────
// Perbaikan lanjutan: komponen uang, paginasi riwayat, ulasan
// ─────────────────────────────────────────────────────────────

void _moneyAndPagingTests() {
  group('OrderTotals', () {
    test('total = subtotal + ongkir - diskon', () {
      const t = OrderTotals(
        subtotal: 116000,
        shippingFee: 8000,
        discountAmount: 5000,
      );
      expect(t.total, 119000);
    });

    test('tanpa ongkir, labelnya "Gratis" bukan "Rp0"', () {
      const t = OrderTotals(subtotal: 64000);
      expect(t.shippingLabel, 'Gratis');
      expect(t.hasShipping, isFalse);
      expect(t.total, 64000);
    });

    test('diskon tidak membuat total negatif', () {
      const t = OrderTotals(subtotal: 20000, discountAmount: 50000);
      expect(t.effectiveDiscount, 20000);
      expect(t.total, 0);
    });

    test('diskon dipotong tetap menyisakan ongkir yang ditagihkan', () {
      const t = OrderTotals(
        subtotal: 20000,
        shippingFee: 9000,
        discountAmount: 50000,
      );
      expect(t.total, 9000);
    });

    test('diskon nol tidak dianggap ada potongan', () {
      const t = OrderTotals(subtotal: 10000);
      expect(t.hasDiscount, isFalse);
    });
  });

  group('formatRupiah', () {
    test('memakai pemisah ribuan Indonesia', () {
      expect(formatRupiah(3450000), 'Rp3.450.000');
      expect(formatRupiah(116000), 'Rp116.000');
      expect(formatRupiah(1000), 'Rp1.000');
      expect(formatRupiah(999), 'Rp999');
      expect(formatRupiah(0), 'Rp0');
    });

    test('nominal negatif diberi tanda di depan', () {
      expect(formatRupiah(-5000), '-Rp5.000');
    });

    test('nominal sangat besar tidak kehilangan digit', () {
      expect(formatRupiah(98765432109), 'Rp98.765.432.109');
    });
  });

  group('Rincian pembayaran pesanan', () {
    test('pesanan lama tanpa komponen tidak menampilkan rincian', () {
      final order = _order(subtotal: 0, totalAmount: 64000);
      expect(order.hasPaymentBreakdown, isFalse);
    });

    test('pesanan dengan komponen menampilkan rincian', () {
      final order = _order(subtotal: 64000, totalAmount: 64000);
      expect(order.hasPaymentBreakdown, isTrue);
    });

    test(
      'komponen string Decimal dari backend dibaca sebagai rupiah bulat',
      () {
        final model = OrderModel.fromJson({
          'id': 'o1',
          'customerId': 'c1',
          'subtotal': '116000.00',
          'shippingFee': '8000.00',
          'discountAmount': '5000.00',
          'totalAmount': '119000.00',
          'status': 'COMPLETED',
          'paymentMethod': 'QRIS',
          'paymentStatus': 'PAID',
          'deliveryAddressId': 'a1',
          'items': <dynamic>[],
        });
        expect(model.subtotal, 116000);
        expect(model.shippingFee, 8000);
        expect(model.discountAmount, 5000);
      },
    );

    test('komponen yang tidak dikirim backend lama dibaca nol', () {
      final model = OrderModel.fromJson({
        'id': 'o1',
        'customerId': 'c1',
        'totalAmount': 64000,
        'status': 'COMPLETED',
        'paymentMethod': 'COD',
        'paymentStatus': 'PAID',
        'deliveryAddressId': 'a1',
        'items': <dynamic>[],
      });
      expect(model.subtotal, 0);
      expect(model.shippingFee, 0);
      expect(model.discountAmount, 0);
    });
  });

  group('OrderSummary', () {
    testWidgets('menampilkan subtotal, ongkir, diskon, dan total', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderSummary(
              totals: OrderTotals(
                subtotal: 116000,
                shippingFee: 8000,
                discountAmount: 5000,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Rp116.000'), findsOneWidget);
      expect(find.text('Rp8.000'), findsOneWidget);
      expect(find.text('-Rp5.000'), findsOneWidget);
      expect(find.text('Rp119.000'), findsOneWidget);
    });

    testWidgets('tanpa diskon, barisnya tidak digambar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderSummary(totals: OrderTotals(subtotal: 64000)),
          ),
        ),
      );
      expect(find.text('Diskon'), findsNothing);
      expect(find.text('Gratis'), findsOneWidget);
      // Total sama dengan subtotal — tidak ada biaya yang ditambahkan layar.
      expect(find.text('Rp64.000'), findsNWidgets(2));
    });
  });

  group('OrderHistoryState', () {
    test('halaman pertama tanpa lanjutan tidak menawarkan muat-lebih', () {
      const state = OrderHistoryState(orders: [], hasMore: false, total: 0);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('copyWith mempertahankan daftar saat menandai sedang memuat', () {
      final state = OrderHistoryState(
        orders: [_order(subtotal: 1000, totalAmount: 1000)],
        hasMore: true,
        total: 25,
      );
      final loading = state.copyWith(isLoadingMore: true);
      expect(loading.orders, hasLength(1));
      expect(loading.total, 25);
      expect(loading.hasMore, isTrue);
    });

    test(
      'gagal memuat halaman berikutnya tidak menghapus yang sudah tampil',
      () {
        final state = OrderHistoryState(
          orders: [_order(subtotal: 1000, totalAmount: 1000)],
          hasMore: true,
          isLoadingMore: true,
          total: 25,
        );
        final failed = state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
        );
        expect(failed.orders, hasLength(1));
        expect(failed.loadMoreFailed, isTrue);
      },
    );
  });

  group('ReviewableItem', () {
    test('kunci memakai id produk yang terisi', () {
      const kopdes = ReviewableItem(productId: 'p1', name: 'Beras');
      const umkm = ReviewableItem(umkmProductId: 'u1', name: 'Kue Adee');
      expect(kopdes.key, 'p1');
      expect(umkm.key, 'u1');
    });

    test('dibaca dari respons backend', () {
      final item = ReviewableItem.fromJson({
        'productId': null,
        'umkmProductId': 'u9',
        'name': 'Kue Adee',
      });
      expect(item.umkmProductId, 'u9');
      expect(item.productId, isNull);
      expect(item.name, 'Kue Adee');
    });
  });
}

Order _order({required int subtotal, required double totalAmount}) => Order(
  id: 'order-1',
  customerId: 'c1',
  subtotal: subtotal,
  totalAmount: totalAmount,
  status: 'COMPLETED',
  paymentMethod: 'QRIS',
  paymentStatus: 'PAID',
  deliveryAddressId: 'a1',
  items: const [],
  createdAt: DateTime(2026, 9, 17),
  updatedAt: DateTime(2026, 9, 17),
);
