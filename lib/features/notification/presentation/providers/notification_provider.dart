import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_item.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]) {
    _seedNotifications();
  }

  void _seedNotifications() {
    state = [
      NotificationItem(
        id: '1',
        type: NotificationType.orderSuccess,
        title: 'Pesanan Berhasil',
        description: 'Pesanan Anda berhasil diproses dan sedang disiapkan oleh Kopdes Merah Putih.',
        timestamp: DateTime(2026, 6, 23, 14, 20),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.deliveryConfirmed,
        title: 'Pengiriman Dikonfirmasi',
        description: 'Kurir telah mengonfirmasi bahwa barang sedang dalam perjalanan menuju lokasi Anda.',
        timestamp: DateTime(2026, 6, 23, 14, 15),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.validationSuccess,
        title: 'Transaksi Selesai',
        description: 'Kurir dan penerima telah melakukan validasi. Transaksi berhasil diselesaikan.',
        timestamp: DateTime(2026, 6, 23, 14, 10),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.newUmkmProduct,
        title: 'Produk UMKM Baru',
        description: 'Keripik Pisang Desa Lamteh telah tersedia di marketplace UMKM.',
        timestamp: DateTime(2026, 6, 22, 10, 30),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        type: NotificationType.aiRecommendation,
        title: 'Rekomendasi AI',
        description: 'AI merekomendasikan stok Mie Instan dan Minyak Goreng untuk ditambah berdasarkan tren penjualan.',
        timestamp: DateTime(2026, 6, 22, 8, 15),
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        type: NotificationType.lowStockAlert,
        title: 'Stok Menipis',
        description: 'Stok Detergen Rinso tersisa 5 unit. Segera lakukan restock.',
        timestamp: DateTime(2026, 6, 21, 17, 0),
        isRead: true,
      ),
      NotificationItem(
        id: '7',
        type: NotificationType.promoUmkm,
        title: 'Promo Produk Lokal',
        description: 'Dapatkan diskon hingga 20% untuk produk UMKM pilihan minggu ini.',
        timestamp: DateTime(2026, 6, 20, 12, 0),
        isRead: true,
      ),
      NotificationItem(
        id: '8',
        type: NotificationType.accountActivity,
        title: 'Akun Berhasil Diperbarui',
        description: 'Informasi profil Anda berhasil diperbarui.',
        timestamp: DateTime(2026, 6, 19, 15, 45),
        isRead: true,
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item
    ];
  }

  void markAllAsRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true)
    ];
  }

  void clearAll() {
    state = [];
  }

  Future<void> refreshNotifications() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _seedNotifications();
  }

  Future<void> loadMoreNotifications() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate loading older historical notifications
    final length = state.length;
    final additional = [
      NotificationItem(
        id: '${length + 1}',
        type: NotificationType.promoUmkm,
        title: 'Diskon Hari Koperasi',
        description: 'Dapatkan penawaran menarik menyambut Hari Koperasi Nasional.',
        timestamp: DateTime(2026, 6, 18, 9, 0),
        isRead: true,
      ),
      NotificationItem(
        id: '${length + 2}',
        type: NotificationType.accountActivity,
        title: 'Keamanan Akun',
        description: 'Kata sandi Anda berhasil diperbarui 7 hari yang lalu.',
        timestamp: DateTime(2026, 6, 17, 16, 30),
        isRead: true,
      ),
    ];
    state = [...state, ...additional];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

// Loading state for infinite scrolling
final isNotificationsLoadingMoreProvider = StateProvider<bool>((ref) => false);
