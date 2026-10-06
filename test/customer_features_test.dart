import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/address/data/address_repository.dart';
import 'package:kopdes/features/address/presentation/address_screens.dart';
import 'package:kopdes/features/order/domain/repositories/order_repository.dart';
import 'package:kopdes/features/order/presentation/providers/order_provider.dart';
import 'package:kopdes/features/order/presentation/providers/cart_provider.dart';
import 'package:kopdes/features/order/presentation/screens/checkout_screen.dart';
import 'package:kopdes/features/payment/data/payment_repository.dart';
import 'package:kopdes/features/payment/presentation/payment_screen.dart';
import 'package:kopdes/features/product/domain/entities/product.dart';
import 'package:kopdes/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:kopdes/features/wallet/data/wallet_repository.dart';
import 'package:kopdes/features/wallet/presentation/wallet_screen.dart';

const _home = Address(
  id: 'a1',
  title: 'Rumah',
  recipientName: 'Cut Nyak Dhien',
  phone: '081234567890',
  street: 'Jl. Teuku Nyak Arief No. 1, Gampong Lamgugop',
  city: 'Banda Aceh',
  state: 'Aceh',
  postalCode: '23115',
  isDefault: true,
);

/// Keranjang tak dipakai di jalur pesan-langsung; tanpa ini cartProvider
/// mencoba membuka Isar.
class _NoOrders implements OrderRepository {
  @override
  dynamic noSuchMethod(Invocation i) => Future<Never>.error('tidak dipakai');
}

class _FakePay extends PaymentRepository {
  PaymentInstructions first;
  PaymentInstructions? next;
  int checks = 0;
  _FakePay(this.first) : super(Dio());

  @override
  Future<PaymentInstructions> payOrder(String orderId, OnlineMethod m) async =>
      first;

  @override
  Future<PaymentInstructions> checkOrder(String orderId) async {
    checks++;
    return next ?? first;
  }
}

class _FakeWallet extends WalletRepository {
  final double bal;
  _FakeWallet(this.bal) : super(Dio());

  @override
  Future<WalletBalance> balance() async =>
      WalletBalance(walletId: 'w', balance: bal);

  @override
  Future<WalletEntriesPage> entries({int page = 1, int limit = 20}) async =>
      WalletEntriesPage(
        entries: [
          WalletEntry(
            id: 'e1',
            amount: 50000,
            balanceAfter: 50000,
            type: 'TOPUP',
            description: null,
            createdAt: DateTime(2026, 10, 4, 16, 20),
          ),
          WalletEntry(
            id: 'e2',
            amount: -15000,
            balanceAfter: 35000,
            type: 'PAYMENT',
            description: null,
            createdAt: DateTime(2026, 10, 4, 17, 0),
          ),
        ],
        page: 1,
        totalPages: 1,
      );
}

PaymentInstructions _pending({
  OnlineMethod m = OnlineMethod.snap,
  String? qr,
  String? va,
  String? snap = 'https://app.sandbox.midtrans.com/snap/v3/redirection/test',
}) => PaymentInstructions(
  status: PayStatus.pending,
  amount: 65000,
  method: m,
  qrCodeUrl: qr,
  vaNumber: va,
  bank: va == null ? null : 'bca',
  expiresAt: DateTime.now().add(const Duration(minutes: 3)),
  snapRedirectUrl: snap,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  double width = 390,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1400),
            textScaler: TextScaler.linear(scale),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('aturan & data', () {
    test('alamat: wajib, ponsel, kode pos', () {
      expect(AddressRules.required(' ', 'Kota'), contains('wajib'));
      expect(AddressRules.phone('0812 3456 7890'), isNull);
      expect(AddressRules.phone('12345'), isNotNull);
      expect(AddressRules.postalCode('23115'), isNull);
      expect(AddressRules.postalCode('2311'), isNotNull);
    });

    test('tagihan pesanan & isi ulang dibaca sama', () {
      final o = PaymentInstructions.fromOrder({
        'status': 'PENDING',
        'grossAmount': 65000,
        'method': 'BCA_VA',
        'vaNumber': '12345678901',
        'bank': 'bca',
        'expiryTime': '2026-10-04T10:00:00.000Z',
      });
      expect(o.status, PayStatus.pending);
      expect(o.method, OnlineMethod.bcaVa);
      expect(o.vaNumber, '12345678901');

      final t = PaymentInstructions.fromTopUp({
        'status': 'PAID',
        'amount': 50000,
        'paymentMethod': 'GOPAY',
        'actions': {'deeplinkUrl': 'gojek://pay'},
      });
      expect(t.status, PayStatus.paid);
      expect(t.deeplinkUrl, 'gojek://pay');
      expect(
        PaymentInstructions.fromOrder({'status': 'EXPIRED'}).status,
        PayStatus.expired,
      );
    });

    test('isi ulang: minimal 10 ribu, maksimal 10 juta', () {
      expect(validateTopUp(''), isNotNull);
      expect(validateTopUp('9000'), contains('Minimal'));
      expect(validateTopUp('10000001'), contains('Maksimal'));
      expect(validateTopUp('50000'), isNull);
    });

    test('profil: nama wajib, HP opsional tapi harus valid', () {
      expect(validateProfileName('ab'), isNotNull);
      expect(validateProfilePhone(''), isNull);
      expect(validateProfilePhone('0812-3456-789'), isNull);
      expect(validateProfilePhone('123'), isNotNull);
    });
  });

  group('pembayaran', () {
    testWidgets('Snap: buka pembayaran, cek status, lalu lunas otomatis', (
      t,
    ) async {
      final repo = _FakePay(_pending());
      await _pump(
        t,
        const PaymentScreen(
          target: (topUp: false, id: 'o1', method: 'MIDTRANS'),
        ),
        overrides: [paymentRepositoryProvider.overrideWithValue(repo)],
      );
      expect(find.text('Rp65.000'), findsOneWidget);
      expect(find.text('Menunggu pembayaran'), findsOneWidget);
      expect(find.text('Buka Midtrans Snap'), findsOneWidget);
      expect(find.text('Cek Status Pembayaran'), findsOneWidget);
      expect(find.text('Ganti Metode Pembayaran'), findsNothing);

      repo.next = PaymentInstructions(
        status: PayStatus.paid,
        amount: 65000,
        method: OnlineMethod.snap,
      );
      await t.pump(PaymentSession.interval);
      await t.pump();
      expect(repo.checks, greaterThanOrEqualTo(1));
      expect(find.text('Pembayaran Diterima'), findsOneWidget);
      expect(find.text('Lihat Pesanan'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('VA: nomor bisa disalin, tanpa QR', (t) async {
      await _pump(
        t,
        const PaymentScreen(target: (topUp: false, id: 'o1', method: 'BCA_VA')),
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            _FakePay(
              _pending(
                m: OnlineMethod.bcaVa,
                qr: null,
                va: '8077000123',
                snap: null,
              ),
            ),
          ),
        ],
      );
      expect(find.text('8077000123'), findsOneWidget);
      expect(find.text('Salin'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('kedaluwarsa: tawarkan bayar ulang', (t) async {
      await _pump(
        t,
        const PaymentScreen(
          target: (topUp: false, id: 'o1', method: 'MIDTRANS'),
        ),
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            _FakePay(
              PaymentInstructions(
                status: PayStatus.expired,
                amount: 65000,
                method: OnlineMethod.snap,
              ),
            ),
          ),
        ],
      );
      expect(find.text('Tagihan Kedaluwarsa'), findsOneWidget);
      expect(find.text('Bayar Ulang'), findsOneWidget);
    });
  });

  group('saldo', () {
    testWidgets('saldo, riwayat, dan validasi isi ulang', (t) async {
      await _pump(
        t,
        const WalletScreen(),
        overrides: [
          walletRepositoryProvider.overrideWithValue(_FakeWallet(35000)),
        ],
      );
      expect(find.text('Rp35.000'), findsOneWidget);
      expect(find.text('Isi ulang'), findsOneWidget);
      expect(find.text('Pembayaran pesanan'), findsOneWidget);
      expect(find.text('−Rp15.000'), findsOneWidget);

      await t.tap(find.text('Isi Ulang Saldo'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '5000');
      await t.pump();
      expect(find.text('Minimal Rp10.000.'), findsOneWidget);
      expect(find.text('Midtrans Snap'), findsOneWidget);
    });
  });

  group('alamat', () {
    testWidgets('kosong: jelaskan kenapa perlu alamat', (t) async {
      await _pump(
        t,
        const AddressListScreen(),
        overrides: [addressesProvider.overrideWith((ref) async => [])],
      );
      expect(find.textContaining('Belum ada alamat'), findsOneWidget);
      expect(find.text('Tambah Alamat'), findsOneWidget);
    });

    testWidgets('daftar: alamat utama ditandai dengan kata', (t) async {
      await _pump(
        t,
        const AddressListScreen(),
        overrides: [
          addressesProvider.overrideWith((ref) async => [_home]),
        ],
      );
      expect(find.text('Utama'), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
      expect(find.text('Jadikan Utama'), findsNothing);
    });
  });

  group('checkout', () {
    final product = Product(
      id: 'p1',
      name: 'Beras 5 kg',
      description: '',
      price: 65000,
      stock: 10,
      categoryId: 'c1',
      images: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    List<Override> base({required List<Address> addresses, double bal = 0}) => [
      orderRepositoryProvider.overrideWithValue(_NoOrders()),
      addressesProvider.overrideWith((ref) async => addresses),
      walletRepositoryProvider.overrideWithValue(_FakeWallet(bal)),
      directCheckoutProvider.overrideWith(
        (ref) => DirectCheckoutData(
          product: product,
          quantity: 1,
          variant: '5 kg',
          deliveryMethod: 'Diantar Kurir',
          paymentMethod: 'Bayar Online',
          price: 65000,
        ),
      ),
    ];

    testWidgets('alamat sungguhan, bukan "Budi Santoso"', (t) async {
      await _pump(
        t,
        const CheckoutScreen(),
        overrides: base(addresses: [_home]),
      );
      expect(find.text('Cut Nyak Dhien (Utama)'), findsOneWidget);
      expect(find.textContaining('Budi Santoso'), findsNothing);
      expect(find.textContaining('Jl. Merdeka'), findsNothing);
    });

    testWidgets('tanpa alamat: ajak tambah alamat', (t) async {
      await _pump(t, const CheckoutScreen(), overrides: base(addresses: []));
      expect(find.textContaining('Belum ada alamat tersimpan'), findsOneWidget);
      expect(find.text('Tambah Alamat'), findsOneWidget);
    });

    testWidgets('ambil sendiri menonaktifkan COD, dengan alasannya', (t) async {
      await _pump(
        t,
        const CheckoutScreen(),
        overrides: base(addresses: [_home]),
      );
      await t.tap(find.text('Ambil Sendiri'));
      await t.pump();
      expect(find.text('Kontak Pesanan'), findsOneWidget);
      expect(
        find.text('Tidak tersedia untuk ambil sendiri — bayar di muka.'),
        findsOneWidget,
      );
    });

    testWidgets('saldo kurang: Saldo KOMIT tidak bisa dipilih', (t) async {
      await _pump(
        t,
        const CheckoutScreen(),
        overrides: base(addresses: [_home], bal: 10000),
      );
      await t.pump();
      expect(find.textContaining('tidak cukup'), findsOneWidget);
      final tile = t.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'Saldo KOMIT'),
      );
      expect(tile.onChanged, isNull);
    });

    for (final (w, sc) in [(320.0, 2.0), (360.0, 1.5), (390.0, 1.0)]) {
      testWidgets('checkout tidak meluber ${w.toInt()}dp ${sc}x', (t) async {
        await _pump(
          t,
          const CheckoutScreen(),
          width: w,
          scale: sc,
          overrides: base(addresses: [_home], bal: 1234567),
        );
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('saldo cukup: langsung lunas', (t) async {
      await _pump(
        t,
        const CheckoutScreen(),
        overrides: base(addresses: [_home], bal: 100000),
      );
      await t.pump();
      expect(find.textContaining('langsung lunas'), findsOneWidget);
    });
  });

  group('tata letak', () {
    for (final (w, s) in [(320.0, 2.0), (360.0, 1.5), (430.0, 1.0)]) {
      testWidgets('halaman baru tidak meluber ${w.toInt()}dp ${s}x', (t) async {
        final pages = <Widget>[
          const PaymentScreen(
            target: (topUp: false, id: 'o1', method: 'BCA_VA'),
          ),
          const WalletScreen(),
          const AddressListScreen(),
          const AddressFormScreen(),
        ];
        for (final page in pages) {
          await _pump(
            t,
            page,
            width: w,
            scale: s,
            overrides: [
              paymentRepositoryProvider.overrideWithValue(
                _FakePay(
                  _pending(
                    m: OnlineMethod.bcaVa,
                    qr: null,
                    va: '80770001234567',
                  ),
                ),
              ),
              walletRepositoryProvider.overrideWithValue(
                _FakeWallet(1234567890),
              ),
              addressesProvider.overrideWith((ref) async => [_home, _home]),
            ],
          );
          expect(
            t.takeException(),
            isNull,
            reason: page.runtimeType.toString(),
          );
          await t.pumpWidget(const SizedBox());
        }
      });
    }
  });
}
