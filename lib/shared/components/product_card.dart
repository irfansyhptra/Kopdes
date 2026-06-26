import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/product_model.dart';
import '../widgets/product_image_loader.dart';

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
    final hasImage = product.images.isNotEmpty;
    final imageUrl = hasImage ? product.images.first.url : '';
    final isLowStock = product.stock <= 5;
    final statusColor = product.isApproved ? AppColors.success : AppColors.warning;
    final statusText = product.isApproved ? 'Disetujui' : 'Menunggu Approval';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: AppElevation.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ProductImageLoader(
                  imageUrl: imageUrl,
                  height: 140,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                // Status Approval
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      statusText,
                      style: AppTypography.badge.copyWith(
                        color: AppColors.onDark,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                // Quick Stock Warning
                if (isLowStock)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.onDark,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category?.name ?? 'Kategori',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    product.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.stock > 0 ? 'Stok: ${product.stock}' : 'Habis',
                        style: AppTypography.captionSmall.copyWith(
                          color: product.stock > 0
                              ? (isLowStock ? AppColors.warning : AppColors.muted)
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: AppColors.muted,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: onEdit,
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: AppColors.errorText,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: onDelete,
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (onToggleActive != null) ...[
                    const Divider(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.isActive ? 'Aktif' : 'Nonaktif',
                          style: AppTypography.captionSmall.copyWith(
                            color: product.isActive ? AppColors.success : AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          width: 40,
                          child: Switch(
                            value: product.isActive,
                            onChanged: onToggleActive,
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
