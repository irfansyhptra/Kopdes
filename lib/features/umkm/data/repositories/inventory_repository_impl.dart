import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_service.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryService service;
  InventoryRepositoryImpl({required this.service});

  @override
  Future<int> adjustStock(String id, int delta, {required String reason}) =>
      service.adjustStock(id, delta, reason: reason);
}
