import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/content_page.dart';

/// Banner "Belanja Lokal, Desa Lebih Kuat".
///
/// Judul dan ajakannya tetap di sini karena ini elemen navigasi — isinya yang
/// panjang berada di halaman tujuan dan dikelola dari backend.
class LocalShoppingBanner extends StatelessWidget {
  const LocalShoppingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: ApplePressable(
        onTap: () => context.push('/info/${ContentSlugs.belanjaLokal}'),
        pressedScale: 0.98,
        semanticLabel:
            'Belanja Lokal, Desa Lebih Kuat. Pelajari dampak belanja produk lokal',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppleRadii.card),
            border: Border.all(color: AppColors.primarySoft),
          ),
          child: Row(
            children: [
              // Ilustrasi sederhana dari ikon, bukan aset gambar: satu baris
              // banner tidak sepadan dengan tambahan berkas ke dalam bundel.
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Belanja Lokal, Desa Lebih Kuat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Setiap pembelian membantu Kopdes dan UMKM berkembang.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
