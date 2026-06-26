import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class StatisticCard extends StatelessWidget {
  final List<dynamic> data;
  final String title;

  const StatisticCard({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    double maxRevenue = 1.0;
    for (var item in data) {
      final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final double revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
                final String day = item['day']?.toString() ?? '';
                final double percentage = revenue / maxRevenue;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatPriceShort(revenue),
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryActive,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AnimatedContainer(
                        duration: AppAnimation.normal,
                        height: (100 * percentage).clamp(10, 100),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryActive],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        day,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPriceShort(double amount) {
    if (amount == 0) return '0';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }
}
