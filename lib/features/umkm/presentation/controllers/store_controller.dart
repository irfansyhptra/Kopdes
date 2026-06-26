import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/store_model.dart';
import '../../domain/repositories/seller_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

final storeProfileProvider = FutureProvider<StoreModel>((ref) async {
  return ref.watch(sellerRepositoryProvider).getStoreProfile();
});

class StoreController extends StateNotifier<AsyncValue<void>> {
  final SellerRepository _repository;
  final Ref _ref;

  StoreController({
    required SellerRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> updateStoreProfile({
    required String businessName,
    required String description,
    required String address,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateStoreProfile(
        businessName: businessName,
        description: description,
        address: address,
        phone: phone,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(storeProfileProvider);
      _ref.read(sellerDashboardControllerProvider.notifier).refresh();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final storeControllerProvider = StateNotifierProvider<StoreController, AsyncValue<void>>((ref) {
  return StoreController(
    repository: ref.watch(sellerRepositoryProvider),
    ref: ref,
  );
});
