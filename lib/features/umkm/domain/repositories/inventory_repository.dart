abstract class InventoryRepository {
  /// [delta] positif = masuk, negatif = keluar. Selalu meninggalkan catatan.
  ///
  /// Mengembalikan stok setelah penyesuaian, menurut server.
  Future<int> adjustStock(String id, int delta, {required String reason});
}
