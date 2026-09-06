import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../data/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';

// Pengelolaan kurir koperasi & penugasan pengantaran.
class CourierManagementScreen extends ConsumerWidget {
  const CourierManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(adminActionProvider);
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              backgroundColor: AppColors.canvas,
              elevation: 0,
              leading: const BackButton(color: AppColors.ink),
              title: Text(
                'Kurir & Pengantaran',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                labelStyle: AppTypography.buttonSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Pengantaran'),
                  Tab(text: 'Kurir'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [_DeliveriesTab(), _CouriersTab()],
            ),
          ),
          ActionOverlay(visible: action is AsyncLoading),
        ],
      ),
    );
  }
}

({Color color, String label}) _deliveryMeta(String status) {
  switch (status) {
    case 'ACCEPTED':
      return (color: AppColors.primary, label: 'Diterima Kurir');
    case 'PICKED_UP':
      return (color: AppColors.primary, label: 'Barang Diambil');
    case 'IN_TRANSIT':
      return (color: AppColors.primary, label: 'Dalam Perjalanan');
    case 'COURIER_DELIVERED':
      return (color: AppColors.warning, label: 'Diantar, Menunggu Konfirmasi');
    case 'CUSTOMER_CONFIRMED':
    case 'COMPLETED':
      return (color: AppColors.success, label: 'Selesai');
    default:
      return (color: AppColors.warning, label: 'Menunggu Penugasan');
  }
}

class _DeliveriesTab extends ConsumerWidget {
  const _DeliveriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(deliveriesProvider);
    return AdminAsyncList<AdminDelivery>(
      value: deliveries,
      onRefresh: () => ref.invalidate(deliveriesProvider),
      emptyTitle: 'Belum ada pengantaran.',
      emptyIcon: Icons.local_shipping_outlined,
      itemBuilder: (d) => _DeliveryCard(delivery: d, ref: ref),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final AdminDelivery delivery;
  final WidgetRef ref;
  const _DeliveryCard({required this.delivery, required this.ref});

  Future<void> _assign(BuildContext context) async {
    final couriers = await ref.read(adminServiceProvider).getCouriers();
    if (!context.mounted) return;
    if (couriers.isEmpty) {
      showSnack(context, 'Belum ada kurir terdaftar', error: true);
      return;
    }
    await showModalBottomSheet(
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
              'Pilih Kurir',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...couriers.map(
              (c) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceSoft,
                  child: Icon(Icons.delivery_dining, color: AppColors.muted),
                ),
                title: Text(c.name, style: AppTypography.bodyMedium),
                subtitle: Text(
                  '${c.activeCount} pengantaran aktif',
                  style: AppTypography.captionSmall,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(adminActionProvider.notifier)
                      .assignCourier(delivery.id, c.id);
                  if (context.mounted) {
                    showSnack(
                      context,
                      ok ? 'Kurir ${c.name} ditugaskan' : 'Gagal menugaskan',
                      error: !ok,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _deliveryMeta(delivery.status);
    final assigned = delivery.courierName != null;
    final displayId = delivery.orderId.isNotEmpty
        ? (delivery.orderId.length >= 8
              ? delivery.orderId.substring(0, 8).toUpperCase()
              : delivery.orderId.toUpperCase())
        : (delivery.id.length >= 8
              ? delivery.id.substring(0, 8).toUpperCase()
              : delivery.id.toUpperCase());

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
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#$displayId',
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
                icon: Icons.local_shipping_rounded,
              ),
            ],
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
                _row(
                  Icons.person_outline_rounded,
                  'Penerima: ${delivery.customerName}',
                ),
                _row(Icons.location_on_outlined, delivery.address),
                _row(
                  Icons.delivery_dining_rounded,
                  assigned
                      ? 'Kurir: ${delivery.courierName}'
                      : 'Belum ada kurir penanggung jawab',
                  color: assigned ? AppColors.primary : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairlineSoft, height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                backgroundColor: assigned ? AppColors.ink : AppColors.primary,
              ),
              icon: Icon(
                assigned
                    ? Icons.swap_horiz_rounded
                    : Icons.assignment_ind_outlined,
                size: 14,
              ),
              label: Text(
                assigned ? 'Ganti Kurir' : 'Tugaskan Kurir',
                style: AppTypography.buttonSm.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _assign(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 2),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.mutedSoft),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.captionSmall.copyWith(
              color: color ?? AppColors.body,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CouriersTab extends ConsumerWidget {
  const _CouriersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriers = ref.watch(couriersProvider);
    return AdminAsyncList<Courier>(
      value: couriers,
      onRefresh: () => ref.invalidate(couriersProvider),
      emptyTitle: 'Belum ada kurir terdaftar.',
      emptyIcon: Icons.delivery_dining,
      itemBuilder: (c) => AdminCard(
        accentColor: c.activeCount > 0 ? AppColors.primary : AppColors.muted,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppColors.mutedSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.phone.isEmpty ? c.email : c.phone,
                        style: AppTypography.captionSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            StatusChip(
              label: '${c.activeCount} pengantaran',
              color: c.activeCount > 0 ? AppColors.primary : AppColors.muted,
              icon: c.activeCount > 0
                  ? Icons.directions_bike_rounded
                  : Icons.pause,
            ),
          ],
        ),
      ),
    );
  }
}
