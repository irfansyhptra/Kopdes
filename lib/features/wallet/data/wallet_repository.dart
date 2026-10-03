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
