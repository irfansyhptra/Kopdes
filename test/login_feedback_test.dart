import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/network/health_provider.dart';
import 'package:kopdes/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kopdes/features/auth/data/models/login_response.dart';
import 'package:kopdes/features/auth/domain/entities/auth_session.dart';
import 'package:kopdes/features/auth/domain/entities/registration_challenge.dart';
import 'package:kopdes/features/auth/domain/entities/user.dart';
import 'package:kopdes/features/auth/domain/repositories/auth_repository.dart';
import 'package:kopdes/features/auth/presentation/providers/auth_provider.dart';
import 'package:kopdes/features/auth/presentation/screens/login_screen.dart';
import 'package:kopdes/shared/widgets/apple_feedback.dart';

/// Repositori yang menahan jawabannya sampai dilepas, supaya keadaan
/// "sedang menunggu" bisa diperiksa, bukan hanya hasil akhirnya.
class _FakeAuthRepository implements AuthRepository {
  final Object? failWith;
  final _gate = Completer<void>();

  _FakeAuthRepository({this.failWith});

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
  Future<RegistrationChallenge> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async =>
      RegistrationChallenge(email: email, expiresIn: 600, resendAfter: 60);

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) => login(email: email, password: code);

  @override
  Future<RegistrationChallenge> resendVerification({
    required String email,
  }) async =>
      RegistrationChallenge(email: email, expiresIn: 600, resendAfter: 60);

  @override
  Future<bool> checkStatus() async => false;
  @override
  Future<User> getCurrentUser() => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession> refreshToken({required String refreshToken}) =>
      throw UnimplementedError();
  @override
  Future<User> updateProfile({required String name, required String phone}) =>
      throw UnimplementedError();
  @override
  Future<User> updateAvatar({
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}

class _FakeLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> clearSession() async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<UserModel?> getUserCached() async => null;
  @override
  Future<String?> getUserRole() async => null;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> saveUserCached(UserModel user) async {}
  @override
  Future<void> saveUserRole(String role) async {}
}

/// Adapter yang menjawab `/health` dengan 200 — tanpa ini layar masuk
/// menganggap server mati dan MEMATIKAN tombolnya.
class _HealthyAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) async =>
      ResponseBody.fromString(
        '{"status":"ok"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

DioException _unauthorized(String? serverMessage) {
  final options = RequestOptions(path: '/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 401,
      data: serverMessage == null ? null : {'message': serverMessage},
    ),
  );
}

Future<void> _pumpLogin(
  WidgetTester tester,
  _FakeAuthRepository repo, {
  bool serverHealthy = true,
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  if (serverHealthy) dio.httpClientAdapter = _HealthyAdapter();

  // Layar uji bawaan 800x600 memotong tombolnya. Lebarnya dilebihkan karena
  // font uji Flutter menggambar tiap huruf selebar satu em, jadi teks di sini
  // jauh lebih lebar daripada di perangkat sungguhan.
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        healthDioProvider.overrideWithValue(dio),
        authRepositoryProvider.overrideWithValue(repo),
        authLocalDataSourceProvider.overrideWithValue(_FakeLocalDataSource()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  // Satu putaran untuk probe kesehatan di initState.
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
  testWidgets('modal memuat tampil selama menunggu jawaban server', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pumpLogin(tester, repo);
    await _fillAndSubmit(tester);

    expect(find.byType(AppleActivityIndicator), findsOneWidget);
    expect(find.text('Sedang masuk ke akunmu…'), findsOneWidget);

    // Dilepas lalu dituntaskan: modal sukses menahan diri ~1,4 detik sebelum
    // menutup sendiri, dan timer itu harus habis sebelum tes berakhir.
    repo.release();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('password salah memunculkan modal gagal dengan pesan server', (
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
    // Menunggu ditutup pengguna, bukan hilang sendiri.
    expect(find.text('Tutup'), findsOneWidget);
  });

  testWidgets('tanpa pesan server pun modalnya menyebut kata sandi', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(failWith: _unauthorized(null));
    await _pumpLogin(tester, repo);
    await _fillAndSubmit(tester);
    repo.release();
    await tester.pumpAndSettle();

    expect(
      find.text('Email tidak terdaftar atau kata sandi salah.'),
      findsOneWidget,
    );
  });

  // Inilah yang dulu membuat modalnya "tidak pernah muncul": probe kesehatan
  // gagal, tombol Masuk jadi onPressed: null, dan menekannya tidak memanggil
  // apa pun — tanpa modal memuat, tanpa modal gagal, tanpa pesan.
  testWidgets('probe kesehatan gagal tidak mematikan tombol Masuk', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pumpLogin(tester, repo, serverHealthy: false);
    await tester.ensureVisible(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Masuk Sekarang'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);

    repo.release();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('server mati: menekan Masuk tetap memunculkan modal', (
    tester,
  ) async {
    final offline = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.connectionError,
    );
    final repo = _FakeAuthRepository(failWith: offline);
    await _pumpLogin(tester, repo, serverHealthy: false);
    await _fillAndSubmit(tester);

    // Modal memuat lebih dulu, bukan layar yang membeku tanpa tanda.
    expect(find.byType(AppleActivityIndicator), findsOneWidget);

    repo.release();
    await tester.pumpAndSettle();

    expect(find.text('Gagal masuk'), findsOneWidget);
    expect(find.textContaining('koneksi'), findsOneWidget);
  });

  testWidgets('kolom isian tidak terkunci saat probe kesehatan gagal', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pumpLogin(tester, repo, serverHealthy: false);

    for (final label in const ['Email', 'Kata Sandi']) {
      final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, label),
      );
      expect(field.enabled, isNot(false), reason: '$label terkunci');
    }

    repo.release();
    await tester.pump();
    await tester.pumpAndSettle();
  });
}
