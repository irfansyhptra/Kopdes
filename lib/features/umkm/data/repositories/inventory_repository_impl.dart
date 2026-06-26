import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_service.dart';
import '../models/inventory_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryService service;
  InventoryRepositoryImpl({required this.service});

  @override
  Future<List<InventoryModel>> getInventoryList() => service.getInventoryList();

  @override
  Future<void> updateStock(String id, int currentStock) => service.updateStock(id, currentStock);
}
