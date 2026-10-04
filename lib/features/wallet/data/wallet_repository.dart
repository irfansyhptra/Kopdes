import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Saldo dompet pengguna.
class WalletBalance {
  final String walletId;
  final double balance;

  const WalletBalance({required this.walletId, required this.balance});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      walletId: json['walletId'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Satu mutasi saldo (`WalletEntry`). `amount` bertanda: + masuk, − keluar.
class WalletEntry {
  final String id;
  final double amount;
  final double balanceAfter;

  /// TOPUP, PAYMENT, REFUND, ADJUSTMENT.
  final String type;
  final String? description;
  final DateTime createdAt;

  const WalletEntry({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  String get label => switch (type) {
    'TOPUP' => 'Isi ulang',
    'PAYMENT' => 'Pembayaran pesanan',
    'REFUND' => 'Pengembalian dana',
    'ADJUSTMENT' => 'Koreksi saldo',
    _ => type,
  };

  factory WalletEntry.fromJson(Map<String, dynamic> j) => WalletEntry(
    id: j['id'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    balanceAfter: (j['balanceAfter'] as num?)?.toDouble() ?? 0,
    type: j['type'] as String? ?? '',
    description: j['description'] as String?,
    createdAt:
        DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now(),
  );
}

class WalletEntriesPage {
  final List<WalletEntry> entries;
  final int page;
  final int totalPages;
  const WalletEntriesPage({
    required this.entries,
    required this.page,
    required this.totalPages,
  });
}

/// Klien dompet.
///
/// Sengaja TIDAK lewat [cachedFetch] seperti daftar produk. Pola cache itu
/// ada supaya katalog tetap bisa dibaca saat jaringan mati — berguna untuk
/// barang, menyesatkan untuk uang. Saldo basi tujuh hari yang ditampilkan
/// seolah terkini adalah angka yang dipakai orang untuk memutuskan menarik
/// dana. Lebih baik gagal dan mengatakannya.
class WalletRepository {
  final Dio dio;

  const WalletRepository(this.dio);

  Future<WalletEntriesPage> entries({int page = 1, int limit = 20}) async {
    final r = await dio.get<dynamic>(
      '/wallet/entries',
      queryParameters: {'page': page, 'limit': limit},
    );
    final d = (r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return WalletEntriesPage(
      entries: (d['entries'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WalletEntry.fromJson)
          .toList(),
      page: (d['page'] as num?)?.toInt() ?? page,
      totalPages: (d['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<WalletBalance> balance() async {
    final response = await dio.get<dynamic>('/wallet');
    final map = response.data as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;
    return WalletBalance.fromJson(data);
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(dioProvider));
});

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) {
  return ref.watch(walletRepositoryProvider).balance();
});
