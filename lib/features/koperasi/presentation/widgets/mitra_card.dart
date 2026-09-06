import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/koperasi.dart';
import 'koperasi_card.dart' show MetaLine;

/// Card Mitra UMKM untuk carousel beranda dan halaman "Lihat Semua".
class MitraCard extends StatelessWidget {
  final Mitra mitra;
  final VoidCallback onVisit;

  /// Beranda memakai lebar tetap untuk carousel; halaman daftar melebar penuh.
  final bool fullWidth;

  const MitraCard({
    super.key,
    required this.mitra,
    required this.onVisit,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppleCard(
      onTap: onVisit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 80,
                width: double.infinity,
                child: ProductImageLoader(
                  imageUrl: mitra.photoUrl ?? '',
                  placeholderIconSize: 24,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: AppleBadge(label: mitra.category.label),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mitra.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Semantics(
                      label: 'Mitra resmi Kopdes',
                      child: const Icon(
                        Icons.handshake_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                MetaLine(
                  rating: mitra.rating,
                  distanceLabel: mitra.distanceLabel,
                  isOpen: mitra.isOpen,
                ),
                const SizedBox(height: 3),
                Text(
                  mitra.description.isEmpty ? mitra.address : mitra.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 11),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ApplePressable(
                    onTap: onVisit,
                    pressedScale: 0.97,
                    semanticLabel: 'Kunjungi ${mitra.businessName}',
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppleRadii.control),
                      ),
                      child: Text(
                        'Kunjungi',
                        style: AppTypography.buttonSm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return fullWidth ? card : SizedBox(width: 224, child: card);
  }
}
