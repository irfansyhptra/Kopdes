import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/network/health_provider.dart';
import 'package:kopdes/core/routing/router.dart';
import 'package:kopdes/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kopdes/features/auth/domain/entities/auth_session.dart';
import 'package:kopdes/features/auth/domain/entities/user.dart';
import 'package:kopdes/features/auth/domain/repositories/auth_repository.dart';
import 'package:kopdes/features/auth/presentation/providers/auth_provider.dart';
import 'package:kopdes/features/auth/presentation/screens/login_screen.dart';
import 'package:kopdes/shared/widgets/apple_feedback.dart';

class _FakeAuthRepository implements AuthRepository {
  final Object? failWith;
  final _gate = Completer<void>();

  _FakeAuthRepository({this.failWith, bool open = false}) {
    if (open) _gate.complete();
  }

  void release() => _gate.complete();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await _gate.future;
    if (failWith != null) throw failWith!;
    return const AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      user: User(
        id: 'u1',
        name: 'Irfan',
        email: 'irfan@example.com',
        phone: '0811',
        role: 'CUSTOMER',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalDataSource implements AuthLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}

class _HealthyAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? __,
  ) async => ResponseBody.fromString(
    '{"status":"ok"}',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

DioException _unauthorized(String message) => DioException(
  requestOptions: RequestOptions(path: '/auth/login'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/auth/login'),
    statusCode: 401,
    data: {'message': message},
  ),
);

List<Override> _overrides(_FakeAuthRepository repo) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = _HealthyAdapter();
  return [
    healthDioProvider.overrideWithValue(dio),
    authRepositoryProvider.overrideWithValue(repo),
    authLocalDataSourceProvider.overrideWithValue(_FakeLocalDataSource()),
  ];
}

Future<void> _pumpLogin(WidgetTester tester, _FakeAuthRepository repo) async {
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(repo),
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'irfan@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kata Sandi'),
    'rahasia123',
  );
  final button = find.text('Masuk Sekarang');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  // `onboardingCompletedProvider` membaca penyimpanan aman lewat kanal
  // platform. Tanpa stub, pembacaannya gagal lalu menyetel state setelah
  // tesnya selesai — berisik, dan tidak ada hubungannya dengan yang diuji.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  group('router bertahan saat status masuk berubah', () {
    // Inilah akar bug "modal tidak pernah muncul di perangkat".
    //
    // `routerProvider` dulu memanggil `ref.watch(authProvider)`, jadi setiap
    // perubahan status — termasuk `loading` yang diset tepat setelah tombol
    // Masuk ditekan — membangun GoRouter baru. `MaterialApp.router` lalu
    // memasang Navigator baru, dan dialog yang baru saja didorong ikut
    // terbuang sebelum sempat terlihat. Tes modal yang memakai `MaterialApp`
    // polos tidak pernah menangkapnya karena di sana tidak ada router.
    test('GoRouter tidak dibuat ulang oleh perubahan status masuk', () async {
      final repo = _FakeAuthRepository(
        failWith: _unauthorized('Email atau password salah'),
        open: true,
      );
      final container = ProviderContainer(overrides: _overrides(repo));
      addTearDown(container.dispose);

      final before = container.read(routerProvider);
      // Beri kesempatan pembacaan penyimpanan aman selesai lebih dulu.
      await Future<void>.delayed(Duration.zero);
      // Dua kali berubah: loading, lalu unauthenticated dengan pesan galat.
      await container.read(authProvider.notifier).login('a@b.c', 'salah');

      expect(container.read(authProvider).errorMessage, isNotNull);
      expect(
        identical(container.read(routerProvider), before),
        isTrue,
        reason:
            'GoRouter dibuat ulang; Navigator baru membuang dialog yang '
            'sedang tampil.',
      );
    });
  });

  group('umpan balik tombol Masuk', () {
    testWidgets('berhasil: tidak ada modal sukses yang menahan ke beranda', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await _pumpLogin(tester, repo);
      await _fillAndSubmit(tester);

      expect(find.text('Sedang masuk ke akunmu…'), findsOneWidget);

      repo.release();
      await tester.pumpAndSettle();

      // Langsung lanjut: tidak ada modal "Berhasil masuk" yang harus
      // ditunggu, dan modal tunggunya sudah ditutup.
      expect(find.text('Berhasil masuk'), findsNothing);
      expect(find.byType(AppleActivityIndicator), findsNothing);
      expect(find.text('Sedang masuk ke akunmu…'), findsNothing);
    });

    testWidgets('gagal: modal galat bertahan sampai ditutup pengguna', (
      tester,
    ) async {
      final repo = _FakeAuthRepository(
        failWith: _unauthorized('Email atau password salah'),
      );
      await _pumpLogin(tester, repo);
      await _fillAndSubmit(tester);
      repo.release();
      await tester.pumpAndSettle();

      expect(find.text('Gagal masuk'), findsOneWidget);
      expect(find.text('Email atau password salah'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Masuk Sekarang'), findsOneWidget);
    });
  });
}
