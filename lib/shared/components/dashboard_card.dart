import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? subtitle;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.bgColor = AppColors.canvas,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkBg =
        bgColor != AppColors.canvas && bgColor != AppColors.surfaceSoft;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isDarkBg ? null : Border.all(color: AppColors.hairlineSoft),
        boxShadow: isDarkBg ? null : AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded, bukan Text telanjang di dalam spaceBetween: judul
              // seperti "Pendapatan Bulan Ini" mendorong ikonnya keluar kartu
              // — 55px di layar 320dp — karena Row tidak pernah menyuruhnya
              // mengalah.
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    color: isDarkBg
                        ? AppColors.onDark.withValues(alpha: 0.7)
                        : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkBg
                      ? AppColors.canvas.withValues(alpha: 0.12)
                      : iconColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDarkBg ? AppColors.onDark : iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Angka mengecil agar muat, bukan terpotong: "Rp2.450.000" di
          // kartu seperempat layar adalah hal pertama yang dicari pemiliknya.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.titleLarge.copyWith(
                color: isDarkBg ? AppColors.onDark : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  color: isDarkBg
                      ? AppColors.onDark.withValues(alpha: 0.5)
                      : AppColors.mutedSoft,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
