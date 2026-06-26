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
    final isDarkBg = bgColor != AppColors.canvas && bgColor != AppColors.surfaceSoft;

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.captionSmall.copyWith(
                  color: isDarkBg ? AppColors.onDark.withOpacity(0.7) : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkBg ? AppColors.canvas.withOpacity(0.12) : iconColor.withOpacity(0.08),
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
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: isDarkBg ? AppColors.onDark : AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTypography.captionSmall.copyWith(
                color: isDarkBg ? AppColors.onDark.withOpacity(0.5) : AppColors.mutedSoft,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
