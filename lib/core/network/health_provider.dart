import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

enum HealthState { checking, healthy, unhealthy }

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((
  ref,
) {
  return HealthNotifier();
});

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(HealthState.checking);

  Future<bool> checkServerHealth() async {
    state = HealthState.checking;
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final dio = Dio();
        final response = await dio
            .get('${ApiConfig.baseUrl}/health')
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          state = HealthState.healthy;
          return true;
        }
      } catch (e) {
        debugPrint('Health check attempt $attempt/$maxAttempts failed: $e');
        if (attempt == maxAttempts) {
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    state = HealthState.unhealthy;
    return false;
  }
}
