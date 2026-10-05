import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/admin/data/kopdes_console.dart';
import 'package:kopdes/features/admin/presentation/screens/mitra_income_screen.dart';

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

Map<String, dynamic> _payload({List<Map<String, dynamic>>? entries}) => {
  'entries':
      entries ??
      [
        {
          'id': 'oi1',
          'soldAt': '2026-10-05T02:00:00.000Z',
          'umkmId': 'u1',
          'umkmName': 'Dapur Bu Sri',
          'productName': 'Keripik Pisang',
          'variantName': null,
          'quantity': 2,
          'gross': 100000,
          'fee': 5000,
        },
      ],
  'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
  'summary': {
    'feePercent': 5,
    'itemsSold': 2,
    'grossAllTime': 100000,
    'feeAllTime': 5000,
    'grossThisMonth': 100000,
    'feeThisMonth': 5000,
  },
};

Future<void> _pump(
  WidgetTester tester,
  _Adapter adapter, {
  double width = 390,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kopdesConsoleServiceProvider.overrideWithValue(
          KopdesConsoleService(dio),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const MitraIncomeScreen()),
            GoRoute(path: '/admin', builder: (_, __) => const Text('konsol')),
          ],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan fee, mitra, dan barangnya', (tester) async {
    final a = _Adapter()..data = _payload();
    await _pump(tester, a);

    expect(a.requests.single.path, '/admin/kopdes/mitra-income');
    expect(find.text('Uang Masuk dari Mitra'), findsOneWidget);
    expect(find.text('Keripik Pisang'), findsOneWidget);
    expect(find.text('Dapur Bu Sri · 2 barang'), findsOneWidget);
    expect(find.text('+Rp5.000'), findsOneWidget);
    expect(find.text('dari Rp100.000'), findsWidgets);
  });

  // Batas yang dijaga: pengurus melihat uangnya, bukan pesanannya.
  testWidgets('tidak menampilkan pembeli, alamat, atau nomor pesanan', (
    tester,
  ) async {
    final a = _Adapter()..data = _payload();
    await _pump(tester, a);

    expect(
      find.textContaining('Isi pesanan mitra'),
      findsOneWidget,
      reason: 'alasannya harus tertulis, bukan sekadar tidak ada datanya',
    );
    for (final bocor in ['Ahmad', 'Jl.', 'Alamat', 'Pembeli']) {
      expect(find.textContaining(bocor), findsNothing, reason: bocor);
    }
  });

  testWidgets('belum ada penjualan selesai: dijelaskan, bukan layar kosong', (
    tester,
  ) async {
    final a = _Adapter()..data = _payload(entries: const []);
    await _pump(tester, a);

    expect(find.text('Belum ada penjualan mitra yang selesai'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('tidak meluber ${width}dp ${scale}x', (tester) async {
        final a = _Adapter()..data = _payload();
        await _pump(tester, a, width: width, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
