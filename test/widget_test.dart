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
          onboardingCompletedProvider.overrideWith((ref) => FakeOnboardingNotifier()),
        ],
        child: const KopdesApp(),
      ),
    );

    // Verify that KopdesApp is present.
    expect(find.byType(KopdesApp), findsOneWidget);

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
