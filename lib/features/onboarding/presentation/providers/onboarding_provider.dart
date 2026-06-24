import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';

final onboardingCompletedProvider = StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  return OnboardingCompletedNotifier(ref.watch(secureStorageProvider));
});

class OnboardingCompletedNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _secureStorage;
  static const String _key = 'onboarding_completed';

  OnboardingCompletedNotifier(this._secureStorage) : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final value = await _secureStorage.read(key: _key);
      state = value == 'true';
    } catch (_) {
      state = false;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _secureStorage.write(key: _key, value: 'true');
      state = true;
    } catch (_) {
      // Fallback in case of storage failure to allow user to proceed
      state = true;
    }
  }

  Future<void> resetOnboarding() async {
    try {
      await _secureStorage.delete(key: _key);
      state = false;
    } catch (_) {
      state = false;
    }
  }
}
