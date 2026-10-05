import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/network/paginated.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/courier/data/courier_models.dart';
import 'package:kopdes/features/courier/data/courier_repository.dart';
import 'package:kopdes/features/courier/data/courier_tracking.dart';
import 'package:kopdes/features/courier/presentation/screens/courier_account_screen.dart';
import 'package:kopdes/features/courier/presentation/screens/courier_console_screen.dart';
import 'package:kopdes/features/courier/presentation/screens/courier_history_screen.dart';
import 'package:kopdes/features/courier/presentation/screens/courier_task_detail_screen.dart';
import 'package:kopdes/features/courier/presentation/screens/courier_tasks_screen.dart';
import 'package:kopdes/features/chat/presentation/providers/chat_providers.dart';
import 'package:kopdes/features/koperasi/presentation/providers/koperasi_provider.dart';

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

Map<String, dynamic> taskJson({
  String id = 'd1',
  String status = 'ACCEPTED',
  String paymentMethod = 'COD',
  String paymentStatus = 'PENDING',
  num codAmount = 95000,
  double? destLat = 5.55,
  double? destLng = 95.31,
}) => {
  'id': id,
  'status': status,
  'acceptedAt': '2026-10-05T01:00:00.000Z',
  'pickedUpAt': null,
  'courierMarkedDeliveredAt': null,
  'customerConfirmedAt': null,
  'createdAt': '2026-10-05T00:30:00.000Z',
  'order': {
    'id': 'order-abcdef123',
    'status': 'READY_FOR_DELIVERY',
    'createdAt': '2026-10-05T00:30:00.000Z',
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'totalAmount': 95000,
    'shippingFee': 5000,
    'codAmount': codAmount,
  },
  'customer': {'id': 'c1', 'name': 'Ahmad Sobari', 'phone': '081360000203'},
  'destination': {
    'title': 'Rumah',
    'recipientName': 'Ahmad Sobari',
    'phone': '081360000203',
    'street': 'Jl. Lamteh No. 4',
    'city': 'Banda Aceh',
    'latitude': destLat,
    'longitude': destLng,
  },
  'pickups': [
    {
      'id': 'kop-1',
      'kind': 'KOPDES',
      'name': 'Kopdes Lamteh',
      'address': 'Jl. Utama No. 1',
      'phone': '0651123456',
      'latitude': 5.56,
      'longitude': 95.30,
    },
  ],
  'items': [
    {'name': 'Beras 5 kg', 'variantName': null, 'quantity': 2},
  ],
  'itemCount': 2,
};

const _summary = CourierSummary(
  availableTasks: 3,
  activeTasks: 1,
  deliveredToday: 4,
  deliveredTotal: 112,
  codCollectedToday: 285000,
);

List<Override> overrides({
  List<Map<String, dynamic>> available = const [],
  List<Map<String, dynamic>> mine = const [],
  Map<String, dynamic>? detail,
  List<Map<String, dynamic>>? history,
  CourierService? service,
}) => [
  // Peta memakai lokasi perangkat; tanpa ini tes memanggil GPS asli.
  userCoordinatesProvider.overrideWithValue(null),
  // Daftar percakapan memanggil jaringan sungguhan dan meninggalkan timer
  // coba-ulang yang membuat tes gagal setelah widget-nya dibuang.
  conversationsProvider.overrideWith((ref) async => []),
  channelConversationsProvider.overrideWith((ref, channel) async => []),
  // Siaran posisi dimatikan di tes: ia menyentuh kanal platform Geolocator.
  courierTrackingSyncProvider.overrideWithValue(null),
  courierSummaryProvider.overrideWith((ref) async => _summary),
  availableTasksProvider.overrideWith(
    (ref) async => available.map(CourierTask.fromJson).toList(),
  ),
  myTasksProvider.overrideWith(
    (ref) async => mine.map(CourierTask.fromJson).toList(),
  ),
  courierTaskProvider.overrideWith(
    (ref, id) async => CourierTask.fromJson(detail ?? taskJson()),
  ),
  // `IndexedStack` membangun kelima tab sekaligus, jadi tab Riwayat ikut
  // hidup di tes dasbor — tanpa stub ia memanggil jaringan sungguhan dan
  // meninggalkan timer coba-ulang.
  courierHistoryProvider.overrideWith(
    (ref) =>
        _StubHistory((history ?? const []).map(CourierTask.fromJson).toList()),
  ),
  courierServiceProvider.overrideWithValue(service ?? _NoopService()),
];

class _StubHistory extends CourierHistoryNotifier {
  _StubHistory(List<CourierTask> items) : super(_NoopService()) {
    state = AsyncData(
      Paginated(items: items, page: 1, totalPages: 1, total: items.length),
    );
  }

  @override
  Future<void> load() async {}
}

class _NoopService extends CourierService {
  _NoopService() : super(Dio());
}

Future<GoRouter> pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  double width = 390,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: '/courier/tugas/:id',
        builder: (_, s) => Text('rute tugas ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const Text('notif')),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const Text('ubah profil'),
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
  await tester.pump();
  await tester.pump();
  return router;
}

void main() {
  group('bentuk data', () {
    test('status tak dikenal tidak menghilangkan tugas dari daftar', () {
      expect(TaskStage.of('SESUATU_YANG_BARU'), TaskStage.assigned);
      expect(TaskStage.of('IN_TRANSIT'), TaskStage.inTransit);
    });

    test('COD belum lunas punya nominal tagihan; yang lunas tidak', () {
      expect(CourierTask.fromJson(taskJson()).isCod, isTrue);
      final paid = CourierTask.fromJson(
        taskJson(paymentMethod: 'QRIS', paymentStatus: 'PAID', codAmount: 0),
      );
      expect(paid.isCod, isFalse);
      expect(paid.codAmount, 0);
    });

    test('nomor pendek dipakai, bukan uuid penuh', () {
      expect(CourierTask.fromJson(taskJson()).shortCode, 'ORDER-AB');
    });

    test('tujuan tanpa titik tetap terbaca sebagai teks', () {
      final t = CourierTask.fromJson(taskJson(destLat: null, destLng: null));
      expect(t.destination.hasPoint, isFalse);
      expect(t.destination.fullAddress, 'Jl. Lamteh No. 4, Banda Aceh');
    });
  });

  group('dasbor kurir', () {
    testWidgets('angka hari ini dan antrean tugas tampil', (tester) async {
      await pump(
        tester,
        const CourierDashboardScreen(),
        overrides: overrides(mine: [taskJson()]),
      );
      await tester.pump();

      expect(find.text('Diantar Hari Ini'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
      expect(find.text('Rp285.000'), findsOneWidget);
      expect(find.text('Tugas tersedia'), findsOneWidget);
      // Lima tab, sama dengan konsol UMKM dan Kopdes.
      for (final tab in ['Dasbor', 'Tugas', 'Riwayat', 'Pesan', 'Akun']) {
        expect(find.text(tab), findsWidgets, reason: tab);
      }
    });

    testWidgets('tugas yang sedang dibawa naik ke paling atas', (tester) async {
      await pump(
        tester,
        const CourierDashboardScreen(),
        overrides: overrides(mine: [taskJson(status: 'IN_TRANSIT')]),
      );
      await tester.pump();

      expect(find.text('Sedang diantar'), findsOneWidget);
      expect(find.text('Lanjutkan Pengantaran'), findsWidgets);
    });
  });

  group('tab Tugas', () {
    testWidgets('tugas tersedia bisa diambil sendiri', (tester) async {
      final a = _Adapter()..data = taskJson();
      await pump(
        tester,
        const CourierTasksScreen(),
        overrides: overrides(
          available: [taskJson(status: 'ASSIGNED')],
          service: CourierService(_dio(a)),
        ),
      );
      await tester.pump();

      expect(find.text('Ambil di Kopdes Lamteh'), findsOneWidget);
      expect(find.text('Antar ke Ahmad Sobari'), findsOneWidget);
      expect(find.text('Tagih Rp95.000'), findsOneWidget);

      await tester.tap(find.text('Ambil Tugas'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(a.requests.single.path, '/courier/deliveries/d1/claim');
      expect(a.requests.single.method, 'POST');
    });

    testWidgets('daftar kosong menjelaskan sebabnya', (tester) async {
      await pump(tester, const CourierTasksScreen(), overrides: overrides());
      await tester.pump();

      expect(find.text('Belum ada tugas yang bisa diambil'), findsOneWidget);
    });
  });

  group('detail tugas', () {
    testWidgets('COD: tombol ambil barang, dan nominal yang harus ditagih', (
      tester,
    ) async {
      await pump(
        tester,
        const CourierTaskDetailScreen(deliveryId: 'd1'),
        overrides: overrides(detail: taskJson(status: 'ACCEPTED')),
      );
      await tester.pump();

      expect(find.text('Barang Sudah Diambil'), findsOneWidget);
      expect(find.text('Tagih ke pembeli'), findsOneWidget);
      expect(find.text('Lepas Tugas Ini'), findsOneWidget);
    });

    testWidgets('pesanan lunas: kurir diperingatkan jangan menagih', (
      tester,
    ) async {
      await pump(
        tester,
        const CourierTaskDetailScreen(deliveryId: 'd1'),
        overrides: overrides(
          detail: taskJson(
            status: 'PICKED_UP',
            paymentMethod: 'QRIS',
            paymentStatus: 'PAID',
            codAmount: 0,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Jangan menagih apa pun. Pesanan ini sudah lunas.'),
        findsOneWidget,
      );
      expect(find.text('Barang Sudah Diantar'), findsOneWidget);
      // Barang sudah di tangan: tidak boleh dilepas begitu saja.
      expect(find.text('Lepas Tugas Ini'), findsNothing);
    });

    testWidgets(
      'tanpa titik rumah, kurir diberi tahu memakai alamat tertulis',
      (tester) async {
        await pump(
          tester,
          const CourierTaskDetailScreen(deliveryId: 'd1'),
          overrides: overrides(detail: taskJson(destLat: null, destLng: null)),
        );
        await tester.pump();

        expect(
          find.textContaining('belum menyimpan titik rumahnya'),
          findsOneWidget,
        );
      },
    );
  });

  group('tab Akun', () {
    testWidgets('nama membuka halaman ubah profil; Kopdes tidak bisa diubah', (
      tester,
    ) async {
      await pump(tester, const CourierAccountScreen(), overrides: overrides());
      await tester.pump();

      await tester.tap(find.text('Nama'));
      await tester.pumpAndSettle();
      expect(find.text('ubah profil'), findsOneWidget);
    });
  });

  group('log pengiriman', () {
    testWidgets('antaran selesai tercatat dengan waktunya', (tester) async {
      final done = taskJson(status: 'COMPLETED');
      done['courierMarkedDeliveredAt'] = '2026-10-05T03:00:00.000Z';
      await pump(
        tester,
        const CourierHistoryScreen(),
        overrides: overrides(history: [done]),
      );
      await tester.pump();

      expect(find.textContaining('Ahmad Sobari'), findsOneWidget);
      expect(find.text('Selesai'), findsWidgets);
    });

    testWidgets('log kosong tidak tampil sebagai layar putih', (tester) async {
      await pump(
        tester,
        const CourierHistoryScreen(),
        overrides: overrides(history: const []),
      );
      await tester.pump();

      expect(find.text('Belum ada antaran selesai'), findsOneWidget);
    });
  });

  group('tata letak', () {
    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('konsol kurir tidak meluber ${width}dp ${scale}x', (
          tester,
        ) async {
          await pump(
            tester,
            const CourierDashboardScreen(),
            overrides: overrides(mine: [taskJson(status: 'IN_TRANSIT')]),
            width: width,
            scale: scale,
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('detail tugas tidak meluber ${width}dp ${scale}x', (
          tester,
        ) async {
          await pump(
            tester,
            const CourierTaskDetailScreen(deliveryId: 'd1'),
            overrides: overrides(),
            width: width,
            scale: scale,
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('tab Tugas tidak meluber ${width}dp ${scale}x', (
          tester,
        ) async {
          await pump(
            tester,
            const CourierTasksScreen(),
            overrides: overrides(available: [taskJson()]),
            width: width,
            scale: scale,
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
