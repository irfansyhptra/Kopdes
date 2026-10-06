import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/order_model.dart';
import '../widgets/apple_ui.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String status)? onUpdateStatus;
  final VoidCallback? onTap;
  final VoidCallback? onChatBuyer;
  final VoidCallback? onChatCourier;

  const OrderCard({
    super.key,
    required this.order,
    this.onUpdateStatus,
    this.onTap,
    this.onChatBuyer,
    this.onChatCourier,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.warning;
      case 'PAID':
        return AppColors.primaryText;
      case 'PROCESSING':
        return AppColors.primaryText;
      case 'READY_FOR_DELIVERY':
        return AppColors.primaryText;
      case 'OUT_FOR_DELIVERY':
        return AppColors.primaryText;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
      default:
        return AppColors.error;
    }
  }

  bool get _pickup => order.fulfillment.toUpperCase() == 'PICKUP';

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'PAID':
        return 'Sudah Dibayar';
      case 'PROCESSING':
        return 'Diproses';
      case 'READY_FOR_DELIVERY':
        return _pickup ? 'Siap Diambil' : 'Butuh Pengantaran';
      case 'OUT_FOR_DELIVERY':
        return 'Dalam Pengiriman';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(order.createdAt);
    final orderIdentity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Pesanan: #${order.id.substring(0, 8).toUpperCase()}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(formattedDate, style: AppTypography.captionSmall),
      ],
    );
    final statusBadge = Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: statusColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            order.status.toUpperCase() == 'CANCELLED'
                ? Icons.cancel_outlined
                : order.status.toUpperCase() == 'COMPLETED' ||
                      order.status.toUpperCase() == 'DELIVERED'
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            size: 13,
            color: statusColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              statusLabel,
              style: AppTypography.badge.copyWith(
                color: statusColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return AppleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Header
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final shouldStack = constraints.maxWidth < 390 || textScale > 1.2;

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    orderIdentity,
                    const SizedBox(height: AppSpacing.sm),
                    statusBadge,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: orderIdentity),
                  const SizedBox(width: AppSpacing.sm),
                  statusBadge,
                ],
              );
            },
          ),
          const Divider(height: AppSpacing.lg),

          // Customer Name & Shipping Info
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  order.customer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          // Pesanan ambil-sendiri tidak punya alamat antar; tanpa penjaga ini
          // barisnya terbaca ", " saja.
          if (order.deliveryAddress.street.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${order.deliveryAddress.street}, ${order.deliveryAddress.city}',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Order items summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.umkmProduct?.name ?? 'Produk UMKM',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.body,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '×${item.quantity}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Rp ${(item.price * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Total Amount
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Total Pendapatan:',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              Text(
                'Rp ${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Action Buttons
          if (onChatBuyer != null || onChatCourier != null) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final shouldStack =
                    constraints.maxWidth < 360 || textScale > 1.2;
                final buyerButton = OutlinedButton.icon(
                  onPressed: onChatBuyer,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text('Chat Pembeli'),
                );
                final courierButton = OutlinedButton.icon(
                  onPressed: onChatCourier,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 17),
                  label: const Text('Chat Kurir'),
                );

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (onChatBuyer != null) buyerButton,
                      if (onChatBuyer != null && onChatCourier != null)
                        const SizedBox(height: AppSpacing.sm),
                      if (onChatCourier != null) courierButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    if (onChatBuyer != null) Expanded(child: buyerButton),
                    if (onChatBuyer != null && onChatCourier != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (onChatCourier != null) Expanded(child: courierButton),
                  ],
                );
              },
            ),
          ],
          if (order.status.toUpperCase() == 'READY_FOR_DELIVERY' &&
              !_pickup) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    order.courier == null
                        ? 'Menunggu kurir Kopdes mengambil barang. Kurir yang '
                              'memilih tugas ini, bukan toko.'
                        : 'Diambil kurir ${order.courier!.name}.',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onUpdateStatus != null) ...[
            if (order.status.toUpperCase() == 'PENDING' ||
                order.status.toUpperCase() == 'PAID') ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onUpdateStatus!('PROCESSING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    'Proses pesanan',
                    style: AppTypography.buttonSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else if (order.status.toUpperCase() == 'PROCESSING') ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onUpdateStatus!('READY_FOR_DELIVERY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    _pickup ? 'Tandai siap diambil' : 'Ajukan pengantaran',
                    style: AppTypography.buttonSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
