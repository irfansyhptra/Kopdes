import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';
import '../../../../core/theme/theme.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationItem item;

  const NotificationCard({super.key, required this.item});

  // Map NotificationType to icon, background color, and foreground color
  Map<String, dynamic> _getTypeTheme(NotificationType type) {
    switch (type) {
      case NotificationType.orderSuccess:
        return {
          'icon': Icons.shopping_bag_outlined,
          'color': const Color(0xFF22C55E), // Success Green
          'bgColor': const Color(0xFFDCFCE7),
        };
      case NotificationType.deliveryConfirmed:
        return {
          'icon': Icons.local_shipping_outlined,
          'color': const Color(0xFF3B82F6), // Blue Info
          'bgColor': const Color(0xFFDBEAFE),
        };
      case NotificationType.validationSuccess:
        return {
          'icon': Icons.check_circle_outline_rounded,
          'color': const Color(0xFF22C55E), // Success Green
          'bgColor': const Color(0xFFDCFCE7),
        };
      case NotificationType.newUmkmProduct:
        return {
          'icon': Icons.storefront_rounded,
          'color': const Color(0xFFF59E0B), // Orange Warning
          'bgColor': const Color(0xFFFEF3C7),
        };
      case NotificationType.aiRecommendation:
        return {
          'icon': Icons.auto_awesome_outlined,
          'color': const Color(0xFF8B5CF6), // Purple
          'bgColor': const Color(0xFFEDE9FE),
        };
      case NotificationType.lowStockAlert:
        return {
          'icon': Icons.inventory_2_outlined,
          'color': const Color(0xFFEF4444), // Red Alert / Error
          'bgColor': const Color(0xFFFEE2E2),
        };
      case NotificationType.promoUmkm:
        return {
          'icon': Icons.local_offer_outlined,
          'color': const Color(0xFFD32F2F), // Kopdes Red
          'bgColor': const Color(0xFFFFEBEE),
        };
      case NotificationType.accountActivity:
        return {
          'icon': Icons.person_outline_rounded,
          'color': const Color(0xFF10B981), // Green
          'bgColor': const Color(0xFFD1FAE5),
        };
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = dt.day;
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year | $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = _getTypeTheme(item.type);
    final isUnread = !item.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFFFF0F3) : Colors.white, // Light red if unread
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isUnread) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container 56x56
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme['bgColor'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    theme['icon'] as IconData,
                    color: theme['color'] as Color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),

              // Notification Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Optional "Baru" Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ink,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          // New Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Baru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Timestamp
                    Text(
                      _formatDateTime(item.timestamp),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.mutedSoft,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      item.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isUnread ? const Color(0xFF1F2937) : AppColors.muted,
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
