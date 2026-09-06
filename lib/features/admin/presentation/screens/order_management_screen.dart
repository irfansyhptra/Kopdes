import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../data/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';
import '../../../chat/presentation/chat_launcher.dart';

// Pengelolaan pesanan koperasi oleh Admin Kopdes.
class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  static const _orderStatuses = <String>[
    'PENDING',
    'PAID',
    'PROCESSING',
    'READY_FOR_DELIVERY',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
  ];

  static const _filters = <String, String?>{
    'Semua': null,
    'Baru': 'PENDING',
    'Dibayar': 'PAID',
    'Diproses': 'PROCESSING',
    'Dikirim': 'OUT_FOR_DELIVERY',
    'Selesai': 'COMPLETED',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    final action = ref.watch(adminActionProvider);
    final activeFilter = ref.watch(orderStatusFilterProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: adminAppBar(context, 'Pengelolaan Pesanan'),
          body: Column(
            children: [
              _OrderFilterBar(active: activeFilter, ref: ref),
              Expanded(
                child: AdminAsyncList<AdminOrder>(
                  value: orders,
                  onRefresh: () => ref.invalidate(adminOrdersProvider),
                  emptyTitle: 'Belum ada pesanan pada kategori ini.',
                  emptyIcon: Icons.receipt_long_outlined,
                  itemBuilder: (o) => _OrderCard(
                    order: o,
                    onChangeStatus: () => _pickStatus(context, ref, o),
                    onChat: () => openChatWith(
                      context,
                      ref,
                      o.customerId,
                      o.customerName,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ActionOverlay(visible: action is AsyncLoading),
      ],
    );
  }

  void _pickStatus(BuildContext context, WidgetRef ref, AdminOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ubah Status Pesanan',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._orderStatuses.map((s) {
              final meta = orderStatusMeta(s);
              final selected = s == order.status;
              return ListTile(
                leading: Icon(Icons.circle, size: 12, color: meta.color),
                title: Text(
                  meta.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (selected) return;
                  final ok = await ref
                      .read(adminActionProvider.notifier)
                      .updateOrderStatus(order.id, s);
                  if (context.mounted) {
                    showSnack(
                      context,
                      ok ? 'Status pesanan diperbarui' : 'Gagal',
                      error: !ok,
                    );
                  }
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterBar extends StatelessWidget {
  final String? active;
  final WidgetRef ref;
  const _OrderFilterBar({required this.active, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.canvas,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        children: OrderManagementScreen._filters.entries.map((e) {
          final selected = active == e.value;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(e.key),
              selected: selected,
              onSelected: (_) =>
                  ref.read(orderStatusFilterProvider.notifier).state = e.value,
              labelStyle: AppTypography.captionSmall.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.body,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(color: AppColors.hairlineSoft),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

({Color color, String label}) orderStatusMeta(String status) {
  switch (status) {
    case 'PENDING':
      return (color: AppColors.warning, label: 'Menunggu Pembayaran');
    case 'PAID':
      return (color: AppColors.primary, label: 'Sudah Dibayar');
    case 'PROCESSING':
      return (color: AppColors.primary, label: 'Diproses');
    case 'READY_FOR_DELIVERY':
      return (color: AppColors.primary, label: 'Siap Dikirim');
    case 'OUT_FOR_DELIVERY':
      return (color: AppColors.primary, label: 'Dalam Pengiriman');
    case 'DELIVERED':
      return (color: AppColors.success, label: 'Terkirim');
    case 'COMPLETED':
      return (color: AppColors.success, label: 'Selesai');
    case 'CANCELLED':
      return (color: AppColors.error, label: 'Dibatalkan');
    default:
      return (color: AppColors.muted, label: status);
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final VoidCallback onChangeStatus;
  final VoidCallback onChat;
  const _OrderCard({
    required this.order,
    required this.onChangeStatus,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final meta = orderStatusMeta(order.status);
    final df = DateFormat('d MMM yyyy, HH:mm');
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return AdminCard(
      accentColor: meta.color,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#$shortId',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StatusChip(
                label: meta.label,
                color: meta.color,
                icon: Icons.circle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            df.format(order.createdAt.toLocal()),
            style: AppTypography.captionSmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: '${order.itemCount} barang',
                      color: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusChip(
                      label: order.paymentMethod,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    StatusChip(
                      label: order.paymentStatus == 'PAID'
                          ? 'Lunas'
                          : 'Belum Lunas',
                      color: order.paymentStatus == 'PAID'
                          ? AppColors.success
                          : AppColors.warning,
                      icon: order.paymentStatus == 'PAID'
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                    ),
                    const Spacer(),
                    Text(
                      rupiah(order.totalAmount),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (order.courierName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kurir: ${order.courierName}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairlineSoft, height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Hubungi Pembeli',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onChat,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Ubah Status'),
                onPressed: onChangeStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
