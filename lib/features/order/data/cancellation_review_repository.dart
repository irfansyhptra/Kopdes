import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../umkm/data/store_scope.dart';

/// Pengajuan pembatalan yang menunggu jawaban toko.
class CancellationRequest {
  final String orderId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? requestedAt;
  final String? reason;
  final String customerName;
  final List<({String name, int quantity})> items;

  const CancellationRequest({
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.items,
    this.requestedAt,
    this.reason,
  });

  String get shortCode => orderId.length <= 8
      ? orderId.toUpperCase()
      : orderId.substring(0, 8).toUpperCase();

  factory CancellationRequest.fromJson(Map<String, dynamic> j) =>
      CancellationRequest(
        orderId: j['id'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        createdAt:
            DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now(),
        requestedAt: DateTime.tryParse('${j['requestedAt']}')?.toLocal(),
        reason: j['reason'] as String?,
        customerName: j['customerName'] as String? ?? 'Pembeli',
        items: ((j['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(
              (i) => (
                name: i['name'] as String? ?? 'Barang',
                quantity: (i['quantity'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList(),
      );
}

/// Antrean pengajuan untuk sisi toko.
///
/// Alamat endpoint-nya mengikuti peran yang masuk: pengurus Kopdes memakai
/// `/admin/orders`, penjual mitra `/seller/orders`. Keduanya menjawab bentuk
/// yang sama, jadi layarnya satu.
class CancellationReviewService {
  final Dio dio;
  final StoreScope scope;

  const CancellationReviewService({required this.dio, required this.scope});

  String get _base => scope.isKopdes ? '/admin/orders' : '/seller/orders';

  Future<List<CancellationRequest>> pending() async {
    final res = await dio.get('$_base/cancellations');
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .cast<Map<String, dynamic>>()
        .map(CancellationRequest.fromJson)
        .toList();
  }

  Future<void> decide(String orderId, bool approve, {String? reason}) =>
      dio.patch(
        '$_base/$orderId/cancellation',
        data: {
          'approve': approve,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
}

final cancellationReviewServiceProvider = Provider<CancellationReviewService>(
  (ref) => CancellationReviewService(
    dio: ref.watch(dioProvider),
    scope: ref.watch(storeScopeProvider),
  ),
);

final pendingCancellationsProvider =
    FutureProvider.autoDispose<List<CancellationRequest>>(
      (ref) => ref.watch(cancellationReviewServiceProvider).pending(),
    );
