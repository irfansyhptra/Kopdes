import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Kepala dasbor pemilik UMKM.
///
/// Bentuknya sengaja sama dengan beranda pelanggan — gradien merah, sudut
/// bawah 28, tanda merek bulat, kapsul aksi, lalu satu baris aksi di kaki —
/// supaya berpindah peran tidak terasa seperti berpindah aplikasi. Yang
/// berbeda hanya isinya: pesanan masuk menggantikan keranjang, dan kolom
/// pencariannya mencari barang dagangan sendiri, bukan katalog desa.
///
/// Kapsulnya memakai [GlassIconButton] yang sama dengan kepala halaman peran
/// lain, bukan salinannya sendiri.
class SellerHeader extends StatelessWidget {
  final String storeName;
  final String statusLabel;
  final bool isVerified;
  final int newOrderCount;
  final int chatCount;
  final int notificationCount;
  final VoidCallback onOrdersTap;
  final VoidCallback onChatTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onAddProductTap;

  const SellerHeader({
    super.key,
    required this.storeName,
    required this.statusLabel,
    required this.isVerified,
    required this.newOrderCount,
    required this.chatCount,
    required this.notificationCount,
    required this.onOrdersTap,
    required this.onChatTap,
    required this.onNotificationTap,
    required this.onSearchTap,
    required this.onAddProductTap,
  });

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
            Row(
              children: [
                _StoreMark(storeName: storeName),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Identity(
                    storeName: storeName,
                    statusLabel: statusLabel,
                    isVerified: isVerified,
                  ),
                ),
                GlassIconButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Pesanan baru',
                  badge: newOrderCount,
                  onDark: true,
                  onTap: onOrdersTap,
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Pesan pembeli',
                  badge: chatCount,
                  onDark: true,
                  onTap: onChatTap,
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassIconButton(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  badge: notificationCount,
                  onDark: true,
                  onTap: onNotificationTap,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SellerSearchRow(
              onSearchTap: onSearchTap,
              onAddProductTap: onAddProductTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inisial toko dalam lingkaran — sejajar dengan tanda "KMP" di beranda
/// pelanggan, tapi menyebut tokonya sendiri.
class _StoreMark extends StatelessWidget {
  final String storeName;

  const _StoreMark({required this.storeName});

  String get _initials {
    final words = storeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words[0].characters.first + words[1].characters.first)
        .toUpperCase();
  }

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
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final String storeName;
  final String statusLabel;
  final bool isVerified;

  const _Identity({
    required this.storeName,
    required this.statusLabel,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Toko Anda',
          style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.2),
        ),
        Row(
          children: [
            Flexible(
              child: Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              // Semantik eksplisit: lencana ini menyampaikan status
              // terverifikasi pengurus, bukan hiasan.
              Semantics(
                label: 'Toko terverifikasi',
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.yellowAccent,
                  size: 15,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFFFB3BC),
              size: 12,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                statusLabel,
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
    );
  }
}

/// Pencarian barang dagangan sendiri, plus satu tombol tambah produk.
///
/// Bentuknya meniru kolom pencarian beranda pelanggan; yang berbeda tujuannya
/// — penjual mencari di etalasenya sendiri, dan aksi utamanya menambah
/// barang, bukan menyaring katalog.
class _SellerSearchRow extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onAddProductTap;

  const _SellerSearchRow({
    required this.onSearchTap,
    required this.onAddProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ApplePressable(
            onTap: onSearchTap,
            semanticLabel: 'Cari produk di toko Anda',
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppElevation.subtle,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: AppColors.mutedSoft,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cari produk di toko Anda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.mutedSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ApplePressable(
          onTap: onAddProductTap,
          pressedScale: 0.92,
          semanticLabel: 'Tambah produk baru',
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              shape: BoxShape.circle,
              boxShadow: AppElevation.subtle,
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
