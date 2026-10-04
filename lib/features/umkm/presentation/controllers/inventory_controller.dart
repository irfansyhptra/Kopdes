import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';
import 'product_controller.dart';

class InventoryController {
  final InventoryRepository _repository;
  final Ref _ref;

  InventoryController({
    required InventoryRepository repository,
    required Ref ref,
  }) : _repository = repository,
       _ref = ref;

  /// Menambah atau mengurangi stok sebanyak [delta], tercatat di buku besar
  /// dengan [reason]. Mengembalikan stok baru menurut server.
  ///
  /// Melempar bila server menolak — pemanggil (lewat `runWithFeedback`)
  /// menampilkan alasannya, mis. "Stok tidak mencukupi".
  Future<int> adjustStock(
    String productId,
    int delta, {
    required String reason,
  }) async {
    final stock = await _repository.adjustStock(
      productId,
      delta,
      reason: reason,
    );
    // Hanya baris ini dan ringkasannya yang berubah — bukan seluruh daftar.
    _ref.read(sellerProductListProvider.notifier).applyStock(productId, stock);
    _ref.invalidate(sellerProductDetailProvider(productId));
    _ref.read(sellerDashboardControllerProvider.notifier).refresh();
    return stock;
  }
}

final inventoryControllerProvider = Provider<InventoryController>((ref) {
  return InventoryController(
    repository: ref.watch(inventoryRepositoryProvider),
    ref: ref,
  );
});
