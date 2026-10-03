import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kopdes/app/app.dart';
import 'package:kopdes/features/auth/presentation/providers/auth_provider.dart';
import 'package:kopdes/features/auth/presentation/screens/login_screen.dart';
import 'package:kopdes/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kopdes/features/auth/data/models/login_response.dart';
import 'package:kopdes/core/network/health_provider.dart';
import 'package:kopdes/features/product/presentation/providers/product_provider.dart';
import 'package:kopdes/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:kopdes/features/onboarding/presentation/providers/permission_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;
  String? role;
  UserModel? user;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUserRole(String role) async {
    this.role = role;
  }

  @override
  Future<void> saveUserCached(UserModel user) async {
    this.user = user;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getUserRole() async => role;

  @override
  Future<UserModel?> getUserCached() async => user;

  @override
  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    role = null;
    user = null;
  }
}

class FakeHealthNotifier extends HealthNotifier {
  // HealthNotifier kini menerima Dio-nya lewat konstruktor supaya batas waktu
  // probe bisa diatur terpisah dari klien API utama. Fake ini tidak pernah
  // menyentuh jaringan, jadi Dio kosong sudah cukup.
  FakeHealthNotifier() : super(Dio());

  @override
  Future<bool> checkServerHealth() async {
    state = HealthState.healthy;
    return true;
  }
}

class FakeOnboardingNotifier extends OnboardingCompletedNotifier {
  FakeOnboardingNotifier() : super(const FlutterSecureStorage()) {
    state = true;
  }
}

/// Layar izin sudah dilewati. Uji ini tentang tujuan sesudah perkenalan, dan
/// tanpa penanda ini router berhenti di `/permissions` — benar untuk pemasangan
/// baru, tetapi bukan yang sedang diperiksa di sini.
class FakePermissionsPrimedNotifier extends PermissionsPrimedNotifier {
  FakePermissionsPrimedNotifier() : super(const FlutterSecureStorage()) {
    state = true;
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final fakeLocalDataSource = FakeAuthLocalDataSource();

    // Build our app and trigger a frame with the overridden local datasource.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authLocalDataSourceProvider.overrideWithValue(fakeLocalDataSource),
          healthProvider.overrideWith((ref) => FakeHealthNotifier()),
          categoriesProvider.overrideWith((ref) => Future.value([])),
          onboardingCompletedProvider.overrideWith(
            (ref) => FakeOnboardingNotifier(),
          ),
          permissionsPrimedProvider.overrideWith(
            (ref) => FakePermissionsPrimedNotifier(),
          ),
        ],
        child: const KopdesApp(),
      ),
    );

    // Verify that KopdesApp is present.
    expect(find.byType(KopdesApp), findsOneWidget);
    expect(
      find.byKey(const ValueKey('kmp-flash-reveal')),
      findsOneWidget,
      reason: 'Splash harus memakai animasi logo KMP Mitra yang baru.',
    );
    final entranceFinder = find.byKey(const ValueKey('kmp-splash-entrance'));
    expect(entranceFinder, findsOneWidget);
    expect(
      tester.widget<FadeTransition>(entranceFinder).opacity.value,
      lessThan(1),
      reason: 'Logo harus mulai dari kondisi transparan.',
    );
    await tester.pump(const Duration(milliseconds: 450));
    final halfwayOpacity = tester
        .widget<FadeTransition>(entranceFinder)
        .opacity
        .value;
    expect(halfwayOpacity, greaterThan(0));
    expect(halfwayOpacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.widget<FadeTransition>(entranceFinder).opacity.value,
      closeTo(1, 0.001),
      reason: 'Logo harus berhenti dalam kondisi terlihat penuh.',
    );

    // Wait for the splash screen minimum display duration (3.4 seconds) and process async events incrementally.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.idle();
    }

    // Pump a few more times to process GoRouter redirects and transitions.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that LoginScreen is rendered.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
