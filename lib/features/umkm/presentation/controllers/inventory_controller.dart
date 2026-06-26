import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory_model.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';
import 'product_controller.dart';

final sellerInventoryProvider = FutureProvider<List<InventoryModel>>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getInventoryList();
});

class InventoryController extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  InventoryController({
    required InventoryRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> updateStock(String productId, int newStock) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateStock(productId, newStock);
      state = const AsyncValue.data(null);
      _ref.invalidate(sellerInventoryProvider);
      _ref.invalidate(sellerProductsProvider);
      _ref.read(sellerDashboardControllerProvider.notifier).refresh();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final inventoryControllerProvider = StateNotifierProvider<InventoryController, AsyncValue<void>>((ref) {
  return InventoryController(
    repository: ref.watch(inventoryRepositoryProvider),
    ref: ref,
  );
});
