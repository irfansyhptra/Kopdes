import 'package:dio/dio.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final Dio dio;
  InventoryService({required this.dio});

  Future<List<InventoryModel>> getInventoryList() async {
    final response = await dio.get(
      '/seller/products',
      queryParameters: {'limit': 100},
    );
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>;
    final list = dataMap['products'] as List? ?? [];
    return list
        .map((p) => InventoryModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Menyesuaikan stok lewat buku besar inventaris.
  ///
  /// BUKAN `PUT /seller/products/:id` seperti sebelumnya. Jalur itu menimpa
  /// angka stok tanpa meninggalkan catatan apa pun, sehingga penyesuaian
  /// dari aplikasi tidak pernah muncul di riwayat maupun di pemantauan
  /// langsung — hanya pergerakan dari checkout dan kasir yang tercatat, dan
  /// selisihnya tidak bisa dijelaskan siapa pun.
  ///
  /// [delta] positif berarti barang masuk, negatif berarti keluar.
  Future<void> adjustStock(String id, int delta, {String? reason}) async {
    if (delta == 0) return;
    await dio.post(
      '/seller/inventory/adjust',
      data: {
        'umkmProductId': id,
        'type': delta > 0 ? 'IN' : 'OUT',
        'quantity': delta.abs(),
        'reason':
            reason ??
            (delta > 0 ? 'Restok dari aplikasi' : 'Pengurangan dari aplikasi'),
      },
    );
  }
}
