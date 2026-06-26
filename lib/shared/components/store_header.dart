import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class StoreHeader extends StatelessWidget {
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String status;

  const StoreHeader({
    super.key,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVerified = status == 'ACTIVE';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            businessName,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.success.withOpacity(0.08)
                                : AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                                size: 12,
                                color: isVerified ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isVerified ? 'Terverifikasi' : 'Pending',
                                style: AppTypography.badge.copyWith(
                                  color: isVerified ? AppColors.success : AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'ID Toko: ${idShort(businessName)}',
                      style: AppTypography.captionSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  address.isNotEmpty ? address : 'Alamat belum diatur',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                phone.isNotEmpty ? phone : 'Kontak belum diatur',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String idShort(String name) {
    if (name.length < 3) return 'UMKM-01';
    return 'UMKM-${name.substring(0, 3).toUpperCase()}-${name.hashCode.toString().substring(0, 3)}';
  }
}
