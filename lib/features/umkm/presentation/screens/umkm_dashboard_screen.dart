import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../localization/app_localizations.dart';

class UMKMDashboardScreen extends StatelessWidget {
  const UMKMDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(localizations?.translate('umkmDashboard') ?? 'Dasbor UMKM'),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // ─── Shop Header ───
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
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
                      'Warung Mandiri Jaya',
                      style: AppTypography.titleMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Mitra UMKM KOPDES Sejak 2025',
                      style: AppTypography.captionSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Terverifikasi ✓',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Revenue Card ───
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendapatan Bulan Ini',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.onDark.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Rp 4.720.000',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '54 Transaksi',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.onDark.withOpacity(0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '+12%',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Mini Stats ───
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'Produk Aktif',
                  value: '12',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickStat(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pesanan Baru',
                  value: '3',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Products List ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Produk',
                style: AppTypography.caption.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Tambah',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _ProductItem(
            name: 'Madu Hutan Alami',
            price: 'Rp 85.000',
            stats: 'Stok: 15 • Terjual: 20',
            inStock: true,
          ),
          _ProductItem(
            name: 'Kopi Robusta Desa',
            price: 'Rp 45.000',
            stats: 'Stok: 32 • Terjual: 14',
            inStock: true,
          ),
          _ProductItem(
            name: 'Keripik Tempe Pedas',
            price: 'Rp 15.000',
            stats: 'Stok: 0 • Terjual: 45',
            inStock: false,
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 22),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.captionSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final String name;
  final String price;
  final String stats;
  final bool inStock;

  const _ProductItem({
    required this.name,
    required this.price,
    required this.stats,
    required this.inStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.hairline,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  price,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(stats, style: AppTypography.captionSmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: inStock
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              inStock ? 'Ready' : 'Habis',
              style: AppTypography.captionSmall.copyWith(
                color: inStock ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
