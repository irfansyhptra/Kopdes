import 'package:dio/dio.dart';

import '../store_scope.dart';

class InventoryService {
  final Dio dio;
  final StoreScope scope;
  InventoryService({required this.dio, this.scope = StoreScope.umkm});

  /// Menyesuaikan stok lewat buku besar inventaris.
  ///
  /// BUKAN `PUT /seller/products/:id` seperti sebelumnya. Jalur itu menimpa
  /// angka stok tanpa meninggalkan catatan apa pun, sehingga penyesuaian
  /// dari aplikasi tidak pernah muncul di riwayat maupun di pemantauan
  /// langsung — hanya pergerakan dari checkout dan kasir yang tercatat, dan
  /// selisihnya tidak bisa dijelaskan siapa pun.
  ///
  /// [delta] positif berarti barang masuk, negatif berarti keluar.
  ///
  /// Mengembalikan `currentStock` dari server — angka yang benar-benar
  /// tersimpan, bukan hasil hitung lokal.
  Future<int> adjustStock(
    String id,
    int delta, {
    required String reason,
  }) async {
    if (delta == 0) throw ArgumentError.value(delta, 'delta', 'tidak boleh 0');
    final response = await dio.post(
      scope.adjust,
      data: {
        scope.adjustKey: id,
        'type': delta > 0 ? 'IN' : 'OUT',
        'quantity': delta.abs(),
        'reason': reason,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return ((data as Map<String, dynamic>)['currentStock'] as num).toInt();
  }
}
