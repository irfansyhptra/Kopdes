import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/marketplace.dart';
import '../providers/marketplace_provider.dart';

/// Delegate grid produk Marketplace.
///
/// Jumlah kolom dihitung dari lebar yang tersedia, bukan dari jenis
/// perangkat. Rasionya ikut skala teks: pada teks besar kartu perlu lebih
/// tinggi, kalau tidak isinya meluber.
///
/// Tinggal di sini, bukan di layar, supaya uji tata letak memakai delegate
/// yang sama persis. Saat keduanya punya salinan sendiri, angka yang meleset
/// hanya ketahuan di perangkat sungguhan.
SliverGridDelegate marketplaceGridDelegate(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    // 0,62 — bukan 0,66: kartu berdiskon punya satu baris harga tambahan,
    // dan dengan font sungguhnya 0,66 meluber 0,65px pada lebar 320dp.
    childAspectRatio: (0.62 / textScale.clamp(1.0, 1.8)).clamp(0.34, 0.62),
  );
}

/// Lencana tipe penjual.
///
/// Warna saja tidak cukup membedakan Kopdes dari UMKM bagi pengguna yang sulit
/// membedakan warna — jadi teksnya selalu ditulis, bukan hanya diwarnai.
class SellerTypeBadge extends StatelessWidget {
  final bool isUmkm;

  const SellerTypeBadge({super.key, required this.isUmkm});

  static const Color _umkmPurple = Color(0xFF7957C8);

  @override
  Widget build(BuildContext context) {
    final color = isUmkm ? _umkmPurple : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isUmkm ? 'UMKM' : 'Kopdes',
        style: AppTypography.badge.copyWith(
          color: AppColors.onPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Kartu produk Marketplace.
///
/// Favorit dan status "sedang ditambahkan" diambil dari provider granular,
/// sehingga menekan favorit satu produk tidak membangun ulang seluruh grid.
class MarketplaceProductCard extends ConsumerWidget {
  final MarketplaceProduct product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const MarketplaceProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(product.id));
    final isAdding = ref.watch(
      addingToCartProvider.select((s) => s.contains(product.id)),
    );

    return AppleCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            // Rasio tetap agar tinggi gambar dapat diprediksi di semua lebar
            // kolom. Sisa tinggi kartu diberikan ke blok teks lewat Expanded
            // di bawah, sehingga teks memotong dirinya sendiri alih-alih
            // meluber saat ukuran teks sistem diperbesar.
            aspectRatio: 1.35,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.surfaceSoft,
                  child: ProductImageLoader(
                    imageUrl: product.imageUrl ?? '',
                    placeholderIconSize: 26,
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _DiscountBadge(percent: product.discountPercent),
                  ),
                Positioned(
                  bottom: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: SellerTypeBadge(isUmkm: product.isUmkm),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    productName: product.name,
                    onTap: () => ref
                        .read(favoriteProductsProvider.notifier)
                        .toggle(product),
                  ),
                ),
                if (product.isOutOfStock)
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _MetaRow(product: product),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: ProductPriceView(product: product)),
                      const SizedBox(width: AppSpacing.sm),
                      AppleAddButton(
                        // Stok habis dan permintaan yang sedang berjalan
                        // sama-sama mematikan tombol.
                        onTap: product.isOutOfStock || isAdding
                            ? null
                            : onAddToCart,
                        semanticLabel: product.isOutOfStock
                            ? '${product.name} stok habis'
                            : 'Tambah ${product.name} ke keranjang',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lencana potongan harga, mis. "-20%".
class _DiscountBadge extends StatelessWidget {
  final int percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '-$percent%',
        style: AppTypography.badge.copyWith(
          color: AppColors.onPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Harga jual, dengan harga coret di sampingnya bila sedang diskon.
///
/// Urutannya sengaja harga-baru dulu: pembaca layar menyebut angka yang
/// dibayar lebih dulu, baru harga sebelumnya yang diberi label — tanpa itu
/// yang terdengar pertama justru harga yang tidak berlaku. Saat ruang sempit
/// harga coret yang mengalah, bukan harga yang dibayar.
class ProductPriceView extends StatelessWidget {
  final MarketplaceProduct product;

  const ProductPriceView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final price = Text(
      formatRupiah(product.effectivePrice),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyLarge.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: product.hasDiscount ? AppColors.primary : AppColors.ink,
      ),
    );

    if (!product.hasDiscount) return price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        price,
        Semantics(
          label: 'Harga sebelum diskon ${formatRupiah(product.price)}',
          child: ExcludeSemantics(
            child: Text(
              formatRupiah(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11.5,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.mutedSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final MarketplaceProduct product;

  const _MetaRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.captionSmall.copyWith(fontSize: 11);

    if (!product.hasRating && product.distanceLabel == null) {
      return Text('Belum ada ulasan', style: style);
    }

    return Row(
      children: [
        if (product.hasRating) ...[
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '${product.ratingLabel} (${product.ratingCount})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(color: AppColors.ink),
            ),
          ),
        ],
        if (product.hasRating && product.distanceLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('·', style: style),
          ),
        if (product.distanceLabel != null)
          Flexible(child: Text(product.distanceLabel!, style: style)),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final String productName;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.productName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.85,
      // Statusnya diucapkan, bukan hanya ditandai bentuk hati penuh/kosong.
      semanticLabel: isFavorite
          ? 'Hapus $productName dari favorit'
          : 'Simpan $productName ke favorit',
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppGlass.fillSolidSoft,
              shape: BoxShape.circle,
              boxShadow: AppElevation.hairline,
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 15,
              color: isFavorite ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
