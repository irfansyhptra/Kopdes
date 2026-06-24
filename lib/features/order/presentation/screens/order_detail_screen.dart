import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kopdes/core/theme/theme.dart';
import '../providers/order_provider.dart';
import '../widgets/invoice_viewer.dart';
import '../widgets/order_timeline.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  Widget _buildHeaderButton({
    required Widget child,
    Color backgroundColor = const Color(0x26FFFFFF),
    Color borderColor = const Color(0x1AFFFFFF),
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCustomHeader(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Detail Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildHeaderButton(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              onPressed: () {
                ref.invalidate(orderDetailProvider(orderId));
                ref.invalidate(orderTimelineProvider(orderId));
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderDetailProvider(orderId));
    final actionState = ref.watch(orderActionProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          body: Column(
            children: [
              _buildCustomHeader(context, ref),
              Expanded(
                child: detailAsync.when(
                  data: (order) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  // 1. Status Simulation Panel (Useful for testing)
                  _buildSimulatorPanel(context, ref, order),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Timeline visual tracker
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.hairlineSoft),
                      boxShadow: AppElevation.soft,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: OrderTimeline(currentStatus: order.status),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Invoice rendering
                  InvoiceViewer(order: order),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Shipping Address Card
                  if (order.deliveryAddress != null)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.hairlineSoft),
                        boxShadow: AppElevation.soft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat Pengiriman',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              order.deliveryAddress!.recipientName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.deliveryAddress!.phone,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.deliveryAddress!.street}, ${order.deliveryAddress!.city}, ${order.deliveryAddress!.state}, ${order.deliveryAddress!.postalCode}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('Gagal memuat detail pesanan: $err'),
                    const SizedBox(height: AppSpacing.base),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(orderDetailProvider(orderId)),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),

        // Global Action loading overlay
        if (actionState is AsyncLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSimulatorPanel(
    BuildContext context,
    WidgetRef ref,
    dynamic order,
  ) {
    final statuses = [
      {'status': 'PENDING', 'label': 'Menunggu Pembayaran'},
      {'status': 'PAID', 'label': 'Pembayaran Berhasil'},
      {'status': 'PROCESSING', 'label': 'Diproses'},
      {'status': 'READY_FOR_DELIVERY', 'label': 'Siap Dikirim'},
      {'status': 'OUT_FOR_DELIVERY', 'label': 'Dikirim'},
      {'status': 'DELIVERED', 'label': 'Tiba'},
      {'status': 'COMPLETED', 'label': 'Selesai'},
      {'status': 'CANCELLED', 'label': 'Dibatalkan'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: Colors.blue, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Simulator Alur Status (Pengujian)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: order.status,
              dropdownColor: AppColors.canvas,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: statuses.map((item) {
                return DropdownMenuItem<String>(
                  value: item['status'],
                  child: Text(item['label']!),
                );
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  final success = await ref
                      .read(orderActionProvider.notifier)
                      .updateStatus(order.id, val);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status pesanan diubah menjadi: $val'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
