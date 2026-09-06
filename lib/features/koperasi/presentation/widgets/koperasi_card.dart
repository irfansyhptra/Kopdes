import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/koperasi.dart';

/// Metadata satu baris: rating · jarak · status buka.
///
/// Setiap bagian hilang sendiri kalau datanya tidak ada, sehingga tidak pernah
/// muncul pemisah menggantung seperti "4,8 • • Buka".
class MetaLine extends StatelessWidget {
  final RatingSummary rating;
  final String? distanceLabel;
  final bool? isOpen;

  const MetaLine({
    super.key,
    required this.rating,
    this.distanceLabel,
    this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];

    if (rating.hasRating) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
            const SizedBox(width: 2),
            Text(
              rating.label,
              style: _metaStyle.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      );
    }
    if (distanceLabel != null) {
      parts.add(Text(distanceLabel!, style: _metaStyle));
    }
    if (isOpen != null) {
      // Status tidak disampaikan lewat warna saja — teksnya sendiri sudah
      // menyebutkan "Buka" atau "Tutup".
      parts.add(
        Text(
          isOpen! ? 'Buka' : 'Tutup',
          style: _metaStyle.copyWith(
            color: isOpen! ? AppColors.success : AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (parts.isEmpty) {
      return Text('Belum ada ulasan', style: _metaStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text('•', style: _metaStyle),
            ),
          parts[i],
        ],
      ],
    );
  }

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 11.5,
    color: AppColors.muted,
    height: 1.2,
  );
}

/// Card Kopdes untuk carousel beranda.
class KoperasiCard extends StatelessWidget {
  final Koperasi koperasi;
  final VoidCallback onOpen;
  final VoidCallback onDirections;

  const KoperasiCard({
    super.key,
    required this.koperasi,
    required this.onOpen,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      child: AppleCard(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 84,
              width: double.infinity,
              child: ProductImageLoader(
                imageUrl: koperasi.imageUrl ?? '',
                placeholderIconSize: 26,
              ),
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
                          koperasi.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (koperasi.isVerified) ...[
                        const SizedBox(width: 4),
                        Semantics(
                          label: 'Koperasi terverifikasi',
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  MetaLine(
                    rating: koperasi.rating,
                    distanceLabel: koperasi.distanceLabel,
                    isOpen: koperasi.isOpen,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    koperasi.serviceCategories.isEmpty
                        ? koperasi.shortAddress
                        : koperasi.serviceCategories.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _CardButton(
                          label: 'Lihat Kopdes',
                          filled: true,
                          onTap: onOpen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CardButton(
                          label: 'Petunjuk Arah',
                          icon: Icons.directions_rounded,
                          onTap: onDirections,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: label,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppleRadii.control),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.body),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonSm.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: filled ? AppColors.onPrimary : AppColors.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
