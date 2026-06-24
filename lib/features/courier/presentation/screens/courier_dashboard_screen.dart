import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../localization/app_localizations.dart';

class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          localizations?.translate('courierDashboard') ?? 'Dasbor Kurir',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: AppTypography.captionSmall.copyWith(
                    color: _isOnline ? AppColors.success : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch.adaptive(
                  value: _isOnline,
                  onChanged: (val) => setState(() => _isOnline = val),
                  activeColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // ─── Daily Shift Stats ───
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                _MetricItem(label: 'Pengiriman', value: '6 Paket'),
                _VerticalDivider(),
                _MetricItem(label: 'Pendapatan', value: 'Rp 60.000'),
                _VerticalDivider(),
                _MetricItem(label: 'Jarak', value: '14.2 KM'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Active Tasks ───
          Text(
            'Tugas Pengiriman Aktif',
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DeliveryCard(
            id: 'TRK-9821',
            customer: 'Ahmad Sobari',
            destination: 'Dusun Krajan RT 02 / RW 04, Sendangadi',
            shop: 'Warung Mandiri Jaya',
            payment: 'Rp 95.000 (COD)',
            status: 'IN_TRANSIT',
          ),
          const SizedBox(height: AppSpacing.md),
          _DeliveryCard(
            id: 'TRK-9822',
            customer: 'Bambang Wijaya',
            destination: 'Dusun Nglipar RW 02, Sinduadi',
            shop: 'Toko Kerajinan Lestari',
            payment: 'Lunas (QRIS)',
            status: 'ASSIGNED',
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.captionSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.hairlineSoft);
  }
}

class _DeliveryCard extends StatelessWidget {
  final String id;
  final String customer;
  final String destination;
  final String shop;
  final String payment;
  final String status;

  const _DeliveryCard({
    required this.id,
    required this.customer,
    required this.destination,
    required this.shop,
    required this.payment,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isTransit = status == 'IN_TRANSIT';
    final statusText = isTransit ? 'Sedang Dikirim' : 'Menunggu';
    final statusColor = isTransit ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.captionSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Details
          _DetailRow(icon: Icons.storefront_rounded, text: shop),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(icon: Icons.location_on_outlined, text: destination),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(icon: Icons.payments_outlined, text: payment),
          const SizedBox(height: AppSpacing.base),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Navigasi'),
                  onPressed: () => context.push('/tracking/$id'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status $id diperbarui'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    );
                  },
                  child: Text(isTransit ? 'Selesai' : 'Terima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.captionSmall.copyWith(color: AppColors.body),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
