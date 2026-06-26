import '../../data/models/inventory_model.dart';

abstract class InventoryRepository {
  Future<List<InventoryModel>> getInventoryList();
  Future<void> updateStock(String id, int currentStock);
}
