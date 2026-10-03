import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Arah pergerakan stok, sejalan dengan `InventoryTransactionType` di server.
enum StockMovementType {
  masuk('IN', 'Masuk'),
  keluar('OUT', 'Keluar'),
  koreksi('ADJUSTMENT', 'Koreksi');

  final String wire;
  final String label;
  const StockMovementType(this.wire, this.label);

  static StockMovementType parse(Object? raw) {
    for (final t in StockMovementType.values) {
      if (t.wire == raw) return t;
    }
    return StockMovementType.koreksi;
  }
}

/// Satu baris catatan pergerakan stok.
class StockMovement {
  final String id;
  final StockMovementType type;
  final int quantity;
  final int? stockAfter;
  final String? reason;

  /// Nomor struk kasir. Null berarti pergerakan ini lahir di aplikasi.
  final String? externalRef;
  final String? recordedBy;
  final String? productId;
  final String productName;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.stockAfter,
    required this.reason,
    required this.externalRef,
    required this.recordedBy,
    required this.productId,
    required this.productName,
    required this.createdAt,
  });

  bool get fromPos => externalRef != null;

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return StockMovement(
      id: json['id'] as String? ?? '',
      type: StockMovementType.parse(json['type']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      stockAfter: (json['stockAfter'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      externalRef: json['externalRef'] as String?,
      recordedBy: json['recordedBy'] as String?,
      productId: product?['id'] as String?,
      productName: product?['name'] as String? ?? 'Produk',
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Sepotong umpan pemantauan beserta penanda untuk permintaan berikutnya.
class StockFeedChunk {
  final List<StockMovement> movements;
  final String cursor;
  final bool hasMore;

  const StockFeedChunk({
    required this.movements,
    required this.cursor,
    required this.hasMore,
  });
}

class StockLiveRepository {
  final Dio dio;

  const StockLiveRepository(this.dio);

  /// Mengambil pergerakan setelah [since].
  ///
  /// [since] harus berasal dari `cursor` respons sebelumnya — milik server,
  /// bukan jam perangkat. Jam kasir dan jam ponsel pemilik toko tidak pernah
  /// sama persis, dan selisih beberapa detik sudah cukup untuk melewatkan
  /// satu baris atau menampilkannya dua kali.
  Future<StockFeedChunk> fetch({String? since, int limit = 50}) async {
    final response = await dio.get<dynamic>(
      '/seller/inventory/live',
      queryParameters: {if (since != null) 'since': since, 'limit': limit},
    );

    final map = response.data as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;

    return StockFeedChunk(
      movements: (data['movements'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StockMovement.fromJson)
          .toList(growable: false),
      cursor: data['serverTime'] as String? ?? '',
      hasMore: data['hasMore'] == true,
    );
  }
}

final stockLiveRepositoryProvider = Provider<StockLiveRepository>((ref) {
  return StockLiveRepository(ref.watch(dioProvider));
});
