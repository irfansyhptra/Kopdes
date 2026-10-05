import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/network/paginated.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/admin/data/kopdes_console.dart';
import 'package:kopdes/features/admin/presentation/screens/staff_accounts_screen.dart';
import 'package:kopdes/features/koperasi/domain/koperasi.dart';
import 'package:kopdes/features/koperasi/presentation/providers/koperasi_provider.dart';
import 'package:kopdes/features/umkm/data/models/seller_model.dart';
import 'package:kopdes/features/umkm/data/models/store_model.dart';
import 'package:kopdes/features/umkm/data/services/store_service.dart';
import 'package:kopdes/features/umkm/data/store_scope.dart';
import 'package:kopdes/features/umkm/presentation/controllers/store_controller.dart';
import 'package:kopdes/features/umkm/presentation/screens/store_profile_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/umkm_apply_screen.dart';

/// Merekam permintaan dan menjawab `{success, data}`.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? __,
  ) async {
    requests.add(o);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter a) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = a;

const _kopdesJson = {
  'id': 'k1',
  'name': 'Kopdes Merah Putih Lamteh',
  'description': 'Koperasi desa.',
  'address': 'Jl. Lamteh No. 1',
  'phone': '0651123456',
  'logoUrl': null,
  'operatingHours': {
    'mon': {'open': '08:00', 'close': '17:00'},
  },
  'isVerified': true,
  'isOpen': true,
};

const _stats = SellerDashboardStats(
  totalProducts: 12,
  totalOrders: 40,
  productsSold: 88,
  todayEarnings: 150000,
  todayOrders: 3,
  monthlyEarnings: 4250000,
  monthlyOrders: 61,
  storeRating: 4.6,
  lowStockCount: 2,
  newOrdersCount: 5,
);

const _dashboard = KopdesDashboard(
  stats: _stats,
  pendingMitra: 1,
  pendingPayouts: 2,
);

Future<GoRouter> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  double width = 390,
  double scale = 1.0,
  bool pushed = false,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => pushed ? const Text('asal') : home,
      ),
      GoRoute(path: '/form', builder: (_, __) => home),
      GoRoute(path: '/:a/:b', builder: (_, s) => Text('rute ${s.uri.path}')),
      GoRoute(path: '/:a/:b/:c', builder: (_, s) => Text('rute ${s.uri.path}')),
      GoRoute(
        path: '/:a/:b/:c/:d',
        builder: (_, s) => Text('rute ${s.uri.path}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
  if (pushed) {
    router.push('/form');
    await tester.pumpAndSettle();
  }
  await tester.pump();
  await tester.pump();
  return router;
}

List<Override> get _kopdesTab => [
  storeScopeProvider.overrideWithValue(StoreScope.kopdes),
  storeProfileProvider.overrideWith(
    (ref) async => StoreModel.fromKopdesJson(_kopdesJson),
  ),
  kopdesDashboardProvider.overrideWith((ref) async => _dashboard),
];

void main() {
  group('profil Kopdes memakai halaman toko', () {
    test('respons Kopdes dipetakan ke bentuk profil toko', () {
      final s = StoreModel.fromKopdesJson(_kopdesJson);
      expect(s.businessName, 'Kopdes Merah Putih Lamteh');
      expect(s.isVerified, isTrue);
      expect(s.operatingHours!['mon'], const DayHours('08:00', '17:00'));
      expect(s.operatingHours!['tue'], isNull);
    });

    test(
      'simpan profil Kopdes: alamat Kopdes, kolom `name`, tanpa kategori',
      () async {
        final a = _Adapter()..data = _kopdesJson;
        final service = StoreService(dio: _dio(a), scope: StoreScope.kopdes);
        await service.updateStoreProfile(
          businessName: 'Kopdes Baru',
          category: 'KULINER',
        );
        final req = a.requests.single;
        expect(req.method, 'PUT');
        expect(req.path, '/admin/kopdes/profile');
        expect(req.data, {'name': 'Kopdes Baru'});
      },
    );

    test('rute produk Kopdes dilindungi penjaga /admin', () {
      expect(StoreScope.kopdes.newProductRoute, '/admin/kopdes/products/new');
      expect(StoreScope.kopdes.store, '/admin/kopdes/store');
    });

    testWidgets('tab Koperasi: omzet, menu pengurus, dan tujuannya', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        const StoreProfileScreen(),
        overrides: _kopdesTab,
      );
      expect(find.text('Koperasi Anda'), findsOneWidget);
      expect(find.text('Kopdes terverifikasi'), findsOneWidget);
      expect(find.text('Omzet bulan ini'), findsOneWidget);
      expect(find.text('Rp4.250.000'), findsOneWidget);
      expect(find.text('1 pendaftaran menunggu verifikasi'), findsOneWidget);
      // Kopdes tidak punya dompet penarikan.
      expect(find.text('Tarik saldo'), findsNothing);

      await tester.scrollUntilVisible(find.text('Pegawai & kurir'), 200);
      await tester.tap(find.text('Pegawai & kurir'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/admin/staff');
    });

    for (final width in [320.0, 360.0, 390.0, 768.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('tab Koperasi tidak meluber ${width}dp ${scale}x', (
          tester,
        ) async {
          await _pump(
            tester,
            const StoreProfileScreen(),
            overrides: _kopdesTab,
            width: width,
            scale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('akun pegawai', () {
    testWidgets('akun baru: isian diperiksa, lalu dikirim lengkap', (
      tester,
    ) async {
      final a = _Adapter();
      await _pump(
        tester,
        const StaffFormScreen(),
        pushed: true,
        overrides: [
          kopdesConsoleServiceProvider.overrideWithValue(
            KopdesConsoleService(_dio(a)),
          ),
          permissionCatalogProvider.overrideWith((ref) async => const []),
        ],
      );
      await tester.enterText(find.byType(TextField).at(0), 'Rina');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(find.text('Format email tidak benar.'), findsOneWidget);
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
      expect(a.requests, isEmpty);

      await tester.tap(find.text('Kurir'));
      await tester.enterText(find.byType(TextField).at(1), 'rina@kopdes.id');
      await tester.enterText(find.byType(TextField).at(3), 'rahasia123');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pump(const Duration(seconds: 1));
      final req = a.requests.single;
      expect(req.path, '/admin/staff');
      expect(req.data, {
        'name': 'Rina',
        'password': 'rahasia123',
        'email': 'rina@kopdes.id',
        'role': 'COURIER',
      });
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // Tersimpan → kembali ke halaman sebelumnya.
      expect(find.text('asal'), findsOneWidget);
    });

    for (final width in [320.0, 390.0]) {
      testWidgets('form akun tidak meluber ${width}dp 2.0x', (tester) async {
        await _pump(
          tester,
          const StaffFormScreen(),
          overrides: [
            permissionCatalogProvider.overrideWith((ref) async => const []),
          ],
          width: width,
          scale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('daftar mitra UMKM', () {
    final kopdes = Koperasi.fromJson({
      'id': 'k1',
      'name': 'Kopdes Merah Putih Lamteh',
      'address': 'Jl. Lamteh',
      'village': 'Lamteh',
      'district': 'Ulee Kareng',
      'city': 'Banda Aceh',
      'province': 'Aceh',
      'latitude': 5.5,
      'longitude': 95.3,
      'isVerified': true,
    });
    List<Override> apply(UmkmApplication? app) => [
      myUmkmApplicationProvider.overrideWith((ref) async => app),
      applyKopdesProvider.overrideWith(
        (ref) async =>
            Paginated(items: [kopdes], page: 1, totalPages: 1, total: 1),
      ),
      userCoordinatesProvider.overrideWithValue(null),
    ];

    testWidgets('belum mendaftar: form dengan pilihan Kopdes', (tester) async {
      await _pump(tester, const UmkmApplyScreen(), overrides: apply(null));
      expect(find.text('Kopdes Merah Putih Lamteh'), findsOneWidget);
      await tester.tap(find.text('Kirim Pendaftaran'));
      await tester.pump();
      expect(find.text('Pilih Kopdes desa Anda.'), findsOneWidget);
    });

    testWidgets('sedang ditinjau: status, bukan form', (tester) async {
      await _pump(
        tester,
        const UmkmApplyScreen(),
        overrides: apply(
          const UmkmApplication(
            businessName: 'Warung Mami',
            status: 'PENDING_VERIFICATION',
            kopdesName: 'Kopdes Lamteh',
          ),
        ),
      );
      expect(find.text('Menunggu verifikasi'), findsWidgets);
      expect(find.text('Kirim Pendaftaran'), findsNothing);
    });

    testWidgets('ditolak: alasan tampil dan boleh mengajukan ulang', (
      tester,
    ) async {
      await _pump(
        tester,
        const UmkmApplyScreen(),
        overrides: apply(
          const UmkmApplication(
            businessName: 'Warung Mami',
            status: 'REJECTED',
            rejectionReason: 'Alamat di luar desa',
          ),
        ),
      );
      expect(find.textContaining('Alamat di luar desa'), findsOneWidget);
      expect(find.text('Kirim Pendaftaran'), findsOneWidget);
    });

    for (final width in [320.0, 390.0]) {
      testWidgets('form daftar tidak meluber ${width}dp 2.0x', (tester) async {
        await _pump(
          tester,
          const UmkmApplyScreen(),
          overrides: apply(null),
          width: width,
          scale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
