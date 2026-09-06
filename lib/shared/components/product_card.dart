import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/product_model.dart';
import '../widgets/apple_ui.dart';
import '../widgets/product_image_loader.dart';

/// Card item produk untuk konsol penjual/admin.
///
/// Berbagi kerangka [AppleCard] dengan katalog pelanggan; yang berbeda hanya
/// baris kontrol pengelolaan di bawah — konteksnya kerja, bukan belanja, jadi
/// tidak ada glass dan tidak ada dekorasi tambahan.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueSetter<bool>? onToggleActive;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first.url : '';
    final isLowStock = product.stock > 0 && product.stock <= 5;
    final isOut = product.stock <= 0;

    final (Color stockColor, String stockLabel) = isOut
        ? (AppColors.errorText, 'Stok habis')
        : isLowStock
        ? (AppColors.warning, 'Sisa ${product.stock}')
        : (AppColors.muted, 'Stok ${product.stock}');

    return AppleCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 132,
                width: double.infinity,
                color: AppColors.surfaceSoft,
                child: ProductImageLoader(imageUrl: imageUrl),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: AppleBadge(
                  label: product.isApproved ? 'Tayang' : 'Menunggu verifikasi',
                  color: product.isApproved
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category?.name ?? 'Tanpa kategori',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatRupiah(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Peringatan stok pakai teks + warna, bukan warna saja.
                    Text(
                      stockLabel,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),

                if (onEdit != null ||
                    onDelete != null ||
                    onToggleActive != null) ...[
                  const Divider(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (onToggleActive != null) ...[
                        Expanded(
                          child: Text(
                            product.isActive ? 'Aktif' : 'Nonaktif',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: product.isActive
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: product.isActive,
                          onChanged: onToggleActive,
                          activeThumbColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ] else
                        const Spacer(),
                      if (onEdit != null)
                        _iconAction(
                          Icons.edit_outlined,
                          AppColors.muted,
                          'Ubah produk',
                          onEdit!,
                        ),
                      if (onDelete != null)
                        _iconAction(
                          Icons.delete_outline_rounded,
                          AppColors.errorText,
                          'Hapus produk',
                          onDelete!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Target sentuh 44×44 walau ikonnya 20px — batas minimum Apple HIG.
  Widget _iconAction(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    );
  }
}
