import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/entities/order.dart';

/// Satu pesanan di halaman "Pesanan Dibatalkan".
///
/// Bentuknya sendiri, bukan `Order` penuh: halaman ini hanya perlu
/// menjelaskan apa yang terjadi pada pengajuan, bukan seluruh isi pesanan.
class CancelledOrder {
  final String id;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? requestedAt;
  final String? reason;
  final DateTime? decidedAt;
  final String? rejectReason;
  final CancellationState cancellation;
  final List<({String name, int quantity})> items;

  const CancelledOrder({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.cancellation,
    required this.items,
    this.requestedAt,
    this.reason,
    this.decidedAt,
    this.rejectReason,
  });

  String get shortCode =>
      id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();

  int get totalQuantity => items.fold(0, (n, i) => n + i.quantity);

  static CancellationState _state(Object? v) => switch ('$v') {
    'REQUESTED' => CancellationState.requested,
    'APPROVED' => CancellationState.approved,
    'REJECTED' => CancellationState.rejected,
    _ => CancellationState.none,
  };

  static DateTime? _at(Object? v) =>
      v == null ? null : DateTime.tryParse('$v')?.toLocal();

  factory CancelledOrder.fromJson(Map<String, dynamic> j) => CancelledOrder(
    id: j['id'] as String? ?? '',
    status: j['status'] as String? ?? '',
    paymentMethod: j['paymentMethod'] as String? ?? '',
    totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
    createdAt: _at(j['createdAt']) ?? DateTime.now(),
    requestedAt: _at(j['requestedAt']),
    reason: j['reason'] as String?,
    decidedAt: _at(j['decidedAt']),
    rejectReason: j['rejectReason'] as String?,
    cancellation: _state(j['cancellation']),
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

/// Halaman pembatalan pemesan. Tanpa cache: keputusan toko bisa datang
/// kapan saja, dan daftar yang basi di sini menyesatkan.
final cancellationsProvider = FutureProvider.autoDispose<List<CancelledOrder>>((
  ref,
) async {
  final Dio dio = ref.watch(dioProvider);
  final res = await dio.get('/orders/cancellations');
  final data = res.data as Map<String, dynamic>;
  return ((data['orders'] as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .map(CancelledOrder.fromJson)
      .toList();
});
