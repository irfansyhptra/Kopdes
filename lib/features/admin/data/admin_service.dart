import 'package:dio/dio.dart';
import 'admin_models.dart';

// Klien HTTP untuk seluruh endpoint Admin Kopdes.
// Envelope backend: { success, data }.
class AdminService {
  final Dio dio;
  AdminService({required this.dio});

  List<Map<String, dynamic>> _list(Response res) {
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // ── Mitra UMKM ──
  Future<List<Mitra>> getMitra({String? status, String? search}) async {
    final res = await dio.get(
      '/admin/umkm',
      queryParameters: {
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _list(res).map(Mitra.fromJson).toList();
  }

  Future<void> verifyMitra(String id, String status, {String? reason}) async {
    await dio.patch(
      '/admin/umkm/$id/verify',
      data: {'status': status, if (reason != null) 'rejectionReason': reason},
    );
  }

  // ── Takedown produk UMKM ──
  Future<List<UmkmProductAdmin>> getUmkmProducts({String? search}) async {
    final res = await dio.get(
      '/admin/umkm/products',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _list(res).map(UmkmProductAdmin.fromJson).toList();
  }

  Future<void> setProductActive(
    String id,
    bool isActive, {
    String? reason,
  }) async {
    await dio.patch(
      '/admin/umkm/products/$id/takedown',
      data: {'isActive': isActive, if (reason != null) 'reason': reason},
    );
  }

  // ── Pesanan ──
  Future<List<AdminOrder>> getOrders({String? status}) async {
    final res = await dio.get(
      '/admin/orders',
      queryParameters: {if (status != null) 'status': status},
    );
    return _list(res).map(AdminOrder.fromJson).toList();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await dio.patch('/admin/orders/$id/status', data: {'status': status});
  }

  // ── Kurir & pengantaran ──
  Future<List<Courier>> getCouriers() async {
    final res = await dio.get('/admin/couriers');
    return _list(res).map(Courier.fromJson).toList();
  }

  Future<List<AdminDelivery>> getDeliveries({String? status}) async {
    final res = await dio.get(
      '/admin/deliveries',
      queryParameters: {if (status != null) 'status': status},
    );
    return _list(res).map(AdminDelivery.fromJson).toList();
  }

  Future<void> assignCourier(String deliveryId, String courierId) async {
    await dio.patch(
      '/admin/deliveries/$deliveryId/assign',
      data: {'courierId': courierId},
    );
  }

  /// Mengisi koordinat & profil lokasi Mitra UMKM.
  ///
  /// Tanpa koordinat, UMKM tidak pernah muncul di `/umkm/nearby` — inilah
  /// yang mengisinya. Field yang null tidak dikirim, sehingga admin bisa
  /// memperbarui sebagian saja tanpa menghapus data lain.
  Future<void> updateUmkmLocation(
    String id, {
    double? latitude,
    double? longitude,
    String? category,
  }) async {
    await dio.patch(
      '/admin/umkm/$id/location',
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (category != null) 'category': category,
      },
    );
  }
}
