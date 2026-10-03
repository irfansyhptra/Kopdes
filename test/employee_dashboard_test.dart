import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdes/features/auth/domain/entities/user.dart';
import 'package:kopdes/features/employee/domain/employee_dashboard.dart';
import 'package:kopdes/features/employee/domain/employee_responsive.dart';
import 'package:kopdes/features/employee/presentation/screens/employee_dashboard_page.dart';
import 'package:kopdes/features/employee/presentation/providers/employee_providers.dart';
import 'package:kopdes/features/employee/presentation/widgets/employee_bottom_navigation.dart';

// Ukuran uji: dari ponsel tersempit yang masih dipakai di desa sampai tablet.
const _sizes = <String, Size>{
  '320x568': Size(320, 568),
  '360x800': Size(360, 800),
  '390x844': Size(390, 844),
  '430x932': Size(430, 932),
  '600x960': Size(600, 960),
  '768x1024': Size(768, 1024),
  '1024x1366': Size(1024, 1366),
};

final _pegawai = User(
  id: 'u1',
  name: 'Rahmat Hidayat',
  email: 'rahmat@kopdes.id',
  phone: '0812',
  role: 'PEGAWAI_KOPDES',
  kopdesId: 'kop-1',
  kopdesName: 'Kopdes Merah Putih Lamteh',
  kopdesVillage: 'Lamteh',
  permissions: const [
    Permissions.orderRead,
    Permissions.orderProcess,
    Permissions.productCreate,
    Permissions.deliveryRead,
    Permissions.deliveryAssign,
    Permissions.inventoryRead,
    Permissions.inventoryAdjust,
    Permissions.financeReadSummary,
    Permissions.aiAssist,
  ],
);

/// Pegawai dengan wewenang dipersempit — hanya boleh melihat pesanan.
final _pegawaiTerbatas = User(
  id: 'u2',
  name: 'Sri Wahyuni',
  email: 'sri@kopdes.id',
  phone: '0813',
  role: 'PEGAWAI_KOPDES',
  kopdesId: 'kop-1',
  kopdesName: 'Kopdes Merah Putih Lamteh',
  permissions: const [Permissions.orderRead],
);

const _summary = DashboardSummary(
  newOrders: 12,
  needProcessing: 8,
  readyToShip: 5,
  lowStockProducts: 7,
);

const _stock = StockSummary(activeProducts: 248, lowStock: 7, outOfStock: 3);

FinanceSummary _finance({int? change = 12}) => FinanceSummary(
  period: 'today',
  grossSales: Rupiah.parse('3450000.00'),
  transactionCount: 24,
  refundTotal: Rupiah.zero,
  codTotal: Rupiah.parse('1200000'),
  qrisTotal: Rupiah.parse('2250000'),
  changePercent: change,
  discountTotal: null,
  shippingTotal: null,
);

List<TodayOrder> _orders() => [
  TodayOrder(
    id: 'o1',
    reference: 'KMP-2841',
    customerName: 'Siti Aminah',
    itemCount: 2,
    total: Rupiah.parse('128000'),
    status: EmployeeOrderStatus.paid,
    createdAt: DateTime(2026, 9, 7, 10, 24),
    thumbnailUrl: null,
    deliveryId: null,
    courierAssigned: false,
  ),
  TodayOrder(
    id: 'o2',
    reference: 'KMP-2837',
    customerName: 'M. Yusuf',
    itemCount: 1,
    total: Rupiah.parse('86000'),
    status: EmployeeOrderStatus.readyForDelivery,
    createdAt: DateTime(2026, 9, 7, 9, 17),
    thumbnailUrl: null,
    deliveryId: 'd1',
    courierAssigned: false,
  ),
];

Widget _dashboard({
  User? user,
  List<TodayOrder>? orders,
  bool financeFails = false,
  bool stockFails = false,
}) {
  return ProviderScope(
    overrides: [
      currentStaffProvider.overrideWithValue(user ?? _pegawai),
      employeeSummaryProvider.overrideWith((ref) async => _summary),
      todayOrdersProvider.overrideWith((ref) async => orders ?? _orders()),
      stockSummaryProvider.overrideWith(
        (ref) async => stockFails ? throw Exception('boom') : _stock,
      ),
      financeSummaryProvider.overrideWith(
        (ref) async => financeFails ? throw Exception('boom') : _finance(),
      ),
      storeStatusProvider.overrideWith(
        (ref) async => const StoreStatus(
          kopdesId: 'kop-1',
          name: 'Kopdes Merah Putih Lamteh',
          village: 'Lamteh',
          logoUrl: null,
          isOpen: true,
          opensAt: '07:00',
          closesAt: '17:00',
        ),
      ),
    ],
    child: const MaterialApp(home: KopdesEmployeeDashboardPage()),
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  Widget widget, {
  required Size size,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: widget,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('KopdesResponsiveSpec', () {
    test('memetakan lebar ke kelas tata letak yang benar', () {
      expect(
        KopdesResponsiveSpec.fromWidth(320).size,
        KopdesLayoutSize.compact,
      );
      expect(
        KopdesResponsiveSpec.fromWidth(359).size,
        KopdesLayoutSize.compact,
      );
      expect(KopdesResponsiveSpec.fromWidth(360).size, KopdesLayoutSize.phone);
      expect(KopdesResponsiveSpec.fromWidth(599).size, KopdesLayoutSize.phone);
      expect(KopdesResponsiveSpec.fromWidth(600).size, KopdesLayoutSize.tablet);
      expect(
        KopdesResponsiveSpec.fromWidth(1023).size,
        KopdesLayoutSize.tablet,
      );
      expect(KopdesResponsiveSpec.fromWidth(1024).size, KopdesLayoutSize.large);
    });

    test('layar sempit memakai dua kolom, ponsel standar empat', () {
      expect(KopdesResponsiveSpec.fromWidth(320).kpiColumns, 2);
      expect(KopdesResponsiveSpec.fromWidth(320).quickActionColumns, 2);
      expect(KopdesResponsiveSpec.fromWidth(390).kpiColumns, 4);
      expect(KopdesResponsiveSpec.fromWidth(390).quickActionColumns, 4);
      expect(KopdesResponsiveSpec.fromWidth(1280).quickActionColumns, 8);
    });

    test('lebar konten dibatasi pada tablet dan layar besar', () {
      expect(
        KopdesResponsiveSpec.fromWidth(390).maxContentWidth,
        double.infinity,
      );
      expect(KopdesResponsiveSpec.fromWidth(768).maxContentWidth, 960);
      expect(KopdesResponsiveSpec.fromWidth(1280).maxContentWidth, 1120);
    });

    test('stok & keuangan bertumpuk hanya pada layar tersempit', () {
      expect(KopdesResponsiveSpec.fromWidth(320).sideBySideInsights, isFalse);
      expect(KopdesResponsiveSpec.fromWidth(360).sideBySideInsights, isTrue);
    });
  });

  group('Rupiah', () {
    test('membaca desimal tanpa melewati floating point', () {
      expect(Rupiah.parse('3450000.00').cents, 345000000);
      expect(Rupiah.parse('128000').cents, 12800000);
      expect(Rupiah.parse('0.55').cents, 55);
      expect(Rupiah.parse('').cents, 0);
      expect(Rupiah.parse(null).cents, 0);
    });

    test('memformat dengan pemisah ribuan Indonesia', () {
      expect(Rupiah.parse('3450000.00').formatted, 'Rp3.450.000');
      expect(Rupiah.parse('86000').formatted, 'Rp86.000');
      expect(Rupiah.parse('0').formatted, 'Rp0');
      expect(Rupiah.parse('-25000').formatted, '-Rp25.000');
    });

    test('nominal besar tidak kehilangan presisi', () {
      // Total setahun koperasi; sebagai double dikalikan 100 sudah tidak eksak.
      expect(Rupiah.parse('98765432109.99').cents, 9876543210999);
    });
  });

  group('OrderAction', () {
    test('setiap status memetakan ke tindakan yang benar', () {
      OrderAction? act(EmployeeOrderStatus s, {bool assigned = false}) =>
          OrderAction.forStatus(s, courierAssigned: assigned);

      expect(act(EmployeeOrderStatus.paid)!.label, 'Proses');
      expect(act(EmployeeOrderStatus.paid)!.nextStatus, 'PROCESSING');
      expect(act(EmployeeOrderStatus.processing)!.label, 'Siapkan Barang');
      expect(
        act(EmployeeOrderStatus.processing)!.nextStatus,
        'READY_FOR_DELIVERY',
      );
      expect(
        act(EmployeeOrderStatus.readyForDelivery)!.label,
        'Kirim ke Kurir',
      );
      expect(
        act(EmployeeOrderStatus.readyForDelivery, assigned: true)!.label,
        'Lihat Kurir',
      );
      expect(act(EmployeeOrderStatus.outForDelivery)!.label, 'Lacak');
      expect(act(EmployeeOrderStatus.completed)!.label, 'Lihat Detail');
    });

    test('tindakan yang membuka layar tidak mengubah status', () {
      final track = OrderAction.forStatus(
        EmployeeOrderStatus.outForDelivery,
        courierAssigned: true,
      );
      expect(track!.nextStatus, isNull);
      expect(track.route, isNotNull);
    });
  });

  group('StockSummary', () {
    test('produk sehat adalah sisa setelah menipis dan habis', () {
      expect(_stock.healthy, 238);
      expect(_stock.allHealthy, isFalse);
    });

    test('angka tidak masuk akal tidak menghasilkan sisa negatif', () {
      const weird = StockSummary(activeProducts: 2, lowStock: 5, outOfStock: 5);
      expect(weird.healthy, 0);
    });
  });

  group('Dashboard tidak overflow', () {
    for (final entry in _sizes.entries) {
      testWidgets('pada ${entry.key}', (tester) async {
        await _pumpAt(tester, _dashboard(), size: entry.value);
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.3, 1.5, 2.0]) {
      testWidgets('pada 360dp dengan skala teks ${scale}x', (tester) async {
        await _pumpAt(
          tester,
          _dashboard(),
          size: const Size(360, 800),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pada 320dp dengan skala teks 2.0x', (tester) async {
      await _pumpAt(
        tester,
        _dashboard(),
        size: const Size(320, 568),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Isi dashboard', () {
    testWidgets('menampilkan salam, nama, peran, dan Kopdes', (tester) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('Selamat Bekerja,'), findsOneWidget);
      expect(find.text('Rahmat Hidayat'), findsOneWidget);
      expect(find.text('Pegawai Kopdes'), findsOneWidget);
      expect(find.text('Kopdes Merah Putih Lamteh'), findsOneWidget);
    });

    testWidgets('status toko diambil dari data operasional', (tester) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('Toko Buka'), findsOneWidget);
    });

    testWidgets('empat KPI tampil dengan angka dari endpoint', (tester) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('Pesanan Baru'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Perlu Diproses'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Siap Dikirim'), findsWidgets);
      expect(find.text('Stok Menipis'), findsWidgets);
    });

    testWidgets('delapan tile Akses Cepat tampil', (tester) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      for (final label in [
        'Input Barang',
        'Pesanan Masuk',
        'Atur Pengiriman',
        'Kirim ke Kurir',
        'Lacak Pesanan',
        'Manajemen Stok',
        'Keuangan',
        'AI Assistant',
      ]) {
        // Beberapa label juga muncul sebagai tombol tindakan pesanan,
        // jadi yang diuji keberadaannya, bukan jumlahnya.
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('pesanan menampilkan tombol tindakan sesuai status', (
      tester,
    ) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('#KMP-2841'), findsOneWidget);
      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('Rp128.000'), findsOneWidget);
      expect(find.text('10:24'), findsOneWidget);
      expect(find.text('Proses'), findsOneWidget);
      expect(find.text('Kirim ke Kurir'), findsWidgets);
    });

    testWidgets('keuangan memakai format rupiah dan pembanding', (
      tester,
    ) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('Rp3.450.000'), findsOneWidget);
      expect(find.text('24 Transaksi'), findsOneWidget);
      expect(find.text('+12% dari kemarin'), findsOneWidget);
    });

    testWidgets('banner AI menampilkan insight stok', (tester) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.text('AI Assistant Kopdes'), findsOneWidget);
      expect(find.textContaining('perlu segera direstok'), findsOneWidget);
    });

    testWidgets('navigasi bawah memakai menu pegawai, bukan pelanggan', (
      tester,
    ) async {
      await _pumpAt(tester, _dashboard(), size: const Size(390, 1600));
      expect(find.byType(EmployeeBottomNavigation), findsOneWidget);
      for (final label in ['Beranda', 'Pesanan', 'Stok', 'Profil']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Marketplace'), findsNothing);
      expect(find.text('Keranjang'), findsNothing);
    });
  });

  group('Keadaan kosong dan gagal', () {
    testWidgets('tanpa pesanan menampilkan pesan, bukan daftar kosong', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _dashboard(orders: const []),
        size: const Size(390, 1600),
      );
      expect(find.text('Belum ada pesanan hari ini'), findsOneWidget);
    });

    testWidgets('stok aman ditulis apa adanya', (tester) async {
      await _pumpAt(
        tester,
        ProviderScope(
          overrides: [
            currentStaffProvider.overrideWithValue(_pegawai),
            employeeSummaryProvider.overrideWith((ref) async => _summary),
            todayOrdersProvider.overrideWith((ref) async => const []),
            stockSummaryProvider.overrideWith(
              (ref) async => const StockSummary(
                activeProducts: 10,
                lowStock: 0,
                outOfStock: 0,
              ),
            ),
            financeSummaryProvider.overrideWith((ref) async => _finance()),
            storeStatusProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: KopdesEmployeeDashboardPage()),
        ),
        size: const Size(390, 1600),
      );
      expect(find.text('Semua stok dalam kondisi aman'), findsOneWidget);
    });

    testWidgets('keuangan gagal tidak menjatuhkan pesanan dan stok', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _dashboard(financeFails: true),
        size: const Size(390, 1600),
      );
      expect(find.text('Rekap keuangan belum berhasil dimuat'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsWidgets);
      // Bagian lain tetap hidup.
      expect(find.text('#KMP-2841'), findsOneWidget);
      expect(find.text('Ringkasan Stok'), findsOneWidget);
    });

    testWidgets('jadwal toko belum diatur tidak ditebak sebagai tutup', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        ProviderScope(
          overrides: [
            currentStaffProvider.overrideWithValue(_pegawai),
            employeeSummaryProvider.overrideWith((ref) async => _summary),
            todayOrdersProvider.overrideWith((ref) async => const []),
            stockSummaryProvider.overrideWith((ref) async => _stock),
            financeSummaryProvider.overrideWith((ref) async => _finance()),
            storeStatusProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: KopdesEmployeeDashboardPage()),
        ),
        size: const Size(390, 1600),
      );
      expect(find.text('Jadwal belum diatur'), findsOneWidget);
      expect(find.text('Toko Tutup'), findsNothing);
    });

    testWidgets('perbandingan tanpa data kemarin disembunyikan', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        ProviderScope(
          overrides: [
            currentStaffProvider.overrideWithValue(_pegawai),
            employeeSummaryProvider.overrideWith((ref) async => _summary),
            todayOrdersProvider.overrideWith((ref) async => const []),
            stockSummaryProvider.overrideWith((ref) async => _stock),
            financeSummaryProvider.overrideWith(
              (ref) async => _finance(change: null),
            ),
            storeStatusProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: KopdesEmployeeDashboardPage()),
        ),
        size: const Size(390, 1600),
      );
      expect(find.textContaining('dari kemarin'), findsNothing);
      expect(find.text('24 Transaksi'), findsOneWidget);
    });
  });

  group('Wewenang terbatas', () {
    testWidgets('nominal keuangan tidak ditampilkan tanpa permission', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _dashboard(user: _pegawaiTerbatas),
        size: const Size(390, 1600),
      );
      expect(find.text('Rp3.450.000'), findsNothing);
      expect(find.text('Tidak termasuk wewenang Anda'), findsOneWidget);
    });

    testWidgets('banner AI hilang tanpa permission AI', (tester) async {
      await _pumpAt(
        tester,
        _dashboard(user: _pegawaiTerbatas),
        size: const Size(390, 1600),
      );
      expect(find.text('AI Assistant Kopdes'), findsNothing);
    });

    testWidgets('tile terkunci tetap tampil agar pegawai tahu batasnya', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _dashboard(user: _pegawaiTerbatas),
        size: const Size(390, 1600),
      );
      expect(find.text('Input Barang'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    });

    testWidgets('tile terkunci menolak dengan pesan, bukan diam', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _dashboard(user: _pegawaiTerbatas),
        size: const Size(390, 1600),
      );
      await tester.tap(find.text('Input Barang'));
      await tester.pump();
      expect(
        find.textContaining('tidak termasuk wewenang Anda'),
        findsOneWidget,
      );
    });
  });
}
