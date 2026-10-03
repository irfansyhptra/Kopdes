import '../../data/models/inventory_model.dart';

abstract class InventoryRepository {
  Future<List<InventoryModel>> getInventoryList();

  /// [delta] positif = masuk, negatif = keluar. Selalu meninggalkan catatan.
  Future<void> adjustStock(String id, int delta, {String? reason});
}
