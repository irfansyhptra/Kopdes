import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/discovery.dart';

/// Kartu produk untuk section "Produk UMKM Pilihan" dan "Produk Terlaris".
class DiscoveryProductCard extends StatelessWidget {
  final DiscoveryProduct product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  /// Menampilkan nomor peringkat di pojok gambar — hanya untuk Terlaris.
  final bool showRank;

  const DiscoveryProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.showRank = false,
  });

  @override
  Widget build(BuildContext context) {
    final rank = product.rank;

    return SizedBox(
      width: 148,
      child: Stack(
        children: [
          AppleProductTile(
            imageUrl: product.imageUrl ?? '',
            title: product.name,
            subtitle: product.sellerName,
            price: formatRupiah(product.price),
            imageHeight: 104,
            meta: product.soldLabel,
            // Badge "Produk Lokal" hanya untuk produk mitra; produk Kopdes
            // sudah jelas lokal dan tidak perlu ditandai lagi.
            badge: product.source == ProductSource.umkm ? 'Lokal' : null,
            isFavorite: onFavoriteTap == null ? null : isFavorite,
            onFavoriteTap: onFavoriteTap,
            onTap: onTap,
            // Stok habis mematikan tombol, bukan sekadar mengubah warnanya.
            onAdd: product.isOutOfStock ? null : onAdd,
          ),
          if (showRank && rank != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: _RankBadge(rank: rank),
            ),
          if (product.isOutOfStock)
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Stok habis',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Peringkat $rank terlaris',
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rank <= 3 ? AppColors.primary : AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.canvas, width: 1.5),
        ),
        child: Text(
          '$rank',
          style: AppTypography.badge.copyWith(
            color: AppColors.onPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
