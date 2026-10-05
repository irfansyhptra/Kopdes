import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Keadaan pengantaran sebuah pesanan, dari sudut pandang pemesannya.
class OrderTracking {
  final String deliveryId;
  final String orderId;
  final String status;
  final String? courierName;
  final String? courierPhone;
  final DateTime? courierMarkedDeliveredAt;
  final DateTime? customerConfirmedAt;

  final String destinationLabel;
  final String destinationAddress;
  final double? destinationLat;
  final double? destinationLng;

  /// Titik kurir terakhir. Null berarti kurir belum mengirim posisi sama
  /// sekali — bukan berarti ia berada di koordinat 0,0.
  final double? courierLat;
  final double? courierLng;
  final DateTime? courierSeenAt;

  const OrderTracking({
    required this.deliveryId,
    required this.orderId,
    required this.status,
    required this.destinationLabel,
    required this.destinationAddress,
    this.courierName,
    this.courierPhone,
    this.courierMarkedDeliveredAt,
    this.customerConfirmedAt,
    this.destinationLat,
    this.destinationLng,
    this.courierLat,
    this.courierLng,
    this.courierSeenAt,
  });

  bool get hasCourierPoint => courierLat != null && courierLng != null;
  bool get hasDestinationPoint =>
      destinationLat != null && destinationLng != null;

  /// Kurir sudah membawa barangnya — saat itulah peta berguna.
  bool get isMoving => status == 'PICKED_UP' || status == 'IN_TRANSIT';

  factory OrderTracking.fromJson(Map<String, dynamic> j) {
    final courier = j['courier'] as Map<String, dynamic>?;
    final dest = j['destination'] as Map<String, dynamic>?;
    final last = j['lastLocation'] as Map<String, dynamic>?;
    DateTime? at(Object? v) =>
        v == null ? null : DateTime.tryParse(v as String)?.toLocal();

    return OrderTracking(
      deliveryId: j['deliveryId'] as String? ?? '',
      orderId: j['orderId'] as String? ?? '',
      status: j['status'] as String? ?? '',
      courierName: courier?['name'] as String?,
      courierPhone: courier?['phone'] as String?,
      courierMarkedDeliveredAt: at(j['courierMarkedDeliveredAt']),
      customerConfirmedAt: at(j['customerConfirmedAt']),
      destinationLabel: [
        dest?['recipientName'] as String?,
        dest?['title'] as String?,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      destinationAddress: [
        dest?['street'] as String?,
        dest?['city'] as String?,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
      destinationLat: (dest?['latitude'] as num?)?.toDouble(),
      destinationLng: (dest?['longitude'] as num?)?.toDouble(),
      courierLat: (last?['latitude'] as num?)?.toDouble(),
      courierLng: (last?['longitude'] as num?)?.toDouble(),
      courierSeenAt: at(last?['recordedAt']),
    );
  }
}

/// Pelacakan dibaca per pesanan, bukan per pengantaran: itu yang dipegang
/// pembeli, dan backend memakai kunci yang sama.
final orderTrackingProvider = FutureProvider.autoDispose
    .family<OrderTracking, String>((ref, orderId) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get('/orders/$orderId/tracking');
      final data = (res.data as Map<String, dynamic>)['data'];
      return OrderTracking.fromJson(data as Map<String, dynamic>);
    });

/// Tidak ada websocket di proyek ini, jadi posisi disegarkan berkala selama
/// halaman terbuka. 20 detik: cukup untuk terasa hidup, cukup jarang untuk
/// tidak menghabiskan kuota pembeli yang menonton sambil menunggu.
const trackingPollInterval = Duration(seconds: 20);
