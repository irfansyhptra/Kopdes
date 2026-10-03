import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Header beranda ringkas: sapaan, lokasi, aksi, dan pencarian dalam satu
/// blok gradien setinggi ±175–205px termasuk safe area.
///
/// Terpisah dari `HomeHeaderWidget` yang lama — widget itu masih dipakai
/// layar Marketplace, dan mengubahnya berarti ikut mengubah desain layar lain.
class CompactHomeHeader extends StatelessWidget {
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

  const CompactHomeHeader({
    super.key,
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
  });

  /// Tinggi baris identitas — bagian yang menyusut saat menempel.
  static double identityHeight(BuildContext context) {
    final scale = (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(
      1.0,
      2.0,
    );
    // Diukur, bukan ditebak: 50 pada skala 1,0 dan 99 pada 2,0.
    //
    // Angkanya baru bisa dipakai setelah sapaan dibatasi satu baris —
    // sebelum itu tingginya berubah menurut LEBAR layar (371 pada 320dp,
    // 231 pada 768dp di skala 2,0), dan tidak ada rumus berbasis skala teks
    // yang bisa mewakilinya.
    // +1 sebagai margin pembulatan: pada 1,5x rumus murni memberi 206,5
    // sedangkan tinggi nyatanya 207.
    return 51 + 49 * (scale - 1);
  }

  /// Tinggi penuh, termasuk area aman di atasnya.
  static double expandedHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top +
      AppSpacing.md +
      identityHeight(context) +
      AppSpacing.md +
      _searchHeight +
      AppSpacing.base;

  // 48, bukan 44: itu tinggi Container di dalam HomeSearchBar.
  static const double _searchHeight = 48;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkRed, AppColors.brightRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Potongan lembut di bawah, bukan Stack berisi lingkaran cahaya —
        // satu bentuk saja, tanpa lapisan gradien radial tambahan.
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          topInset + AppSpacing.md,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IdentityRow(
              userName: userName,
              userLocation: userLocation,
              notificationCount: notificationCount,
              cartCount: cartCount,
              chatCount: chatCount,
              onNotificationTap: onNotificationTap,
              onCartTap: onCartTap,
              onChatTap: onChatTap,
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSearchBar(onSearchTap: onSearchTap, onFilterTap: onFilterTap),
          ],
        ),
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  final String userName;
  final String userLocation;
  final int notificationCount;
  final int cartCount;
  final int chatCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final VoidCallback onChatTap;

  const _IdentityRow({
    required this.userName,
    required this.userLocation,
    required this.notificationCount,
    required this.cartCount,
    required this.chatCount,
    required this.onNotificationTap,
    required this.onCartTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandMark(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Satu baris, dipotong bila perlu. Tanpa ini sapaannya
              // membungkus jadi dua-tiga baris pada skala teks besar di
              // layar sempit, dan tinggi header jadi bergantung pada lebar
              // layar — mustahil dihitung untuk sliver yang menempel.
              const Text(
                'Selamat Datang Kembali,',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  height: 1.2,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Semantik ditulis eksplisit: lencana ini menyampaikan status
                  // terverifikasi, bukan sekadar hiasan.
                  Semantics(
                    label: 'Akun terverifikasi',
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.yellowAccent,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFFFB3BC),
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      userLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD5DA),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _HeaderAction(
          icon: Icons.notifications_none_rounded,
          badge: notificationCount,
          label: 'Notifikasi',
          onTap: onNotificationTap,
        ),
        _HeaderAction(
          icon: Icons.shopping_cart_outlined,
          badge: cartCount,
          label: 'Keranjang',
          onTap: onCartTap,
        ),
        _HeaderAction(
          icon: Icons.chat_bubble_outline_rounded,
          badge: chatCount,
          label: 'Pesan',
          onTap: onChatTap,
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x24FFFFFF),
        border: Border.all(color: const Color(0xB3FFFFFF), width: 1.6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'KMP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// Tombol ikon header bergaya glassmorphism, sesuai desain awal:
/// lingkaran putih translusen, tepi putih tipis, dan bayangan lembut.
///
/// Tidak memakai `BackdropFilter`. Tiga tombol ini ikut menggulir bersama
/// header, jadi blur di sini dihitung ulang setiap frame — sementara yang ada
/// di belakangnya hanya gradien statis milik header, sehingga isian translusen
/// memberi hasil visual yang sama tanpa biaya itu. (Blur asli dilepas pada
/// audit performa; bisa dikembalikan kalau memang diinginkan.)
///
/// Lingkarannya 40×40, tetapi area sentuhnya diperluas jadi 44×44.
class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final int badge;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.badge,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.90,
      semanticLabel: badge > 0 ? '$label, $badge baru' : label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF), // putih 18%
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x47FFFFFF), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            if (badge > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brightRed,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kolom pencarian + tombol filter, ditempatkan di kaki header.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const HomeSearchBar({
    super.key,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ApplePressable(
            onTap: onSearchTap,
            pressedScale: 0.99,
            semanticLabel: 'Cari produk',
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.mutedSoft,
                    size: 19,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cari produk kebutuhanmu...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedSoft,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ApplePressable(
          onTap: onFilterTap,
          pressedScale: 0.94,
          semanticLabel: 'Filter produk',
          // Lebar minimum, bukan lebar mati: label boleh menyusut saat
          // pengguna menaikkan ukuran teks sistem, alih-alih meluber.
          child: Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 92, maxWidth: 105),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 17),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Filter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
