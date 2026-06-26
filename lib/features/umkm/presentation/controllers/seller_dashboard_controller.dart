import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/seller_model.dart';
import 'providers.dart';

class SellerDashboardNotifier extends StateNotifier<AsyncValue<SellerModel>> {
  final Ref _ref;
  SellerDashboardNotifier(this._ref) : super(const AsyncValue.loading()) {
    getDashboard();
  }

  Future<void> getDashboard() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(sellerRepositoryProvider);
      final dashboard = await repository.getDashboard();
      state = AsyncValue.data(dashboard);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final repository = _ref.read(sellerRepositoryProvider);
      final dashboard = await repository.getDashboard();
      state = AsyncValue.data(dashboard);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final sellerDashboardControllerProvider =
    StateNotifierProvider<SellerDashboardNotifier, AsyncValue<SellerModel>>((ref) {
  return SellerDashboardNotifier(ref);
});

final sellerStatsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(sellerRepositoryProvider).getStatistics();
});
