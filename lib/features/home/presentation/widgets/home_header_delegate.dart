import 'package:flutter/material.dart';

import 'compact_home_header.dart';

/// Memaku [CompactHomeHeader] di puncak halaman, utuh.
///
/// Tinggi tetap: [minExtent] sama dengan [maxExtent], jadi tidak ada yang
/// menyusut saat digulir. Sapaan, nama, lokasi, ketiga kapsul aksi, dan
/// kolom pencarian tetap pada posisinya dari awal sampai akhir halaman.
///
/// Konsekuensinya header memakan ruangnya secara permanen — itu memang
/// pilihan yang diambil: aksi di header lebih sering dibutuhkan daripada
/// satu baris produk tambahan.
class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final String userLocation;
  final int notificationCount;
  final int cartCount;
  final int chatCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final VoidCallback onChatTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  /// Tinggi penuh header, dari [CompactHomeHeader.expandedHeight].
  final double height;

  const HomeHeaderDelegate({
    required this.userName,
    required this.userLocation,
    required this.notificationCount,
    required this.cartCount,
    required this.chatCount,
    required this.onNotificationTap,
    required this.onCartTap,
    required this.onChatTap,
    required this.onSearchTap,
    required this.onFilterTap,
    required this.height,
  });

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return SizedBox(
      height: height,
      child: CompactHomeHeader(
        userName: userName,
        userLocation: userLocation,
        notificationCount: notificationCount,
        cartCount: cartCount,
        chatCount: chatCount,
        onNotificationTap: onNotificationTap,
        onCartTap: onCartTap,
        onChatTap: onChatTap,
        onSearchTap: onSearchTap,
        onFilterTap: onFilterTap,
      ),
    );
  }

  @override
  bool shouldRebuild(HomeHeaderDelegate old) =>
      old.userName != userName ||
      old.userLocation != userLocation ||
      old.notificationCount != notificationCount ||
      old.cartCount != cartCount ||
      old.chatCount != chatCount ||
      old.height != height;
}
