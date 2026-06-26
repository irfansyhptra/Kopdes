import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/dashboard_card.dart';
import '../../../../shared/components/statistic_card.dart';
import '../../../../shared/components/store_header.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../controllers/seller_dashboard_controller.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(sellerDashboardControllerProvider);
    final statsState = ref.watch(sellerStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Dasbor Penjual'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(sellerDashboardControllerProvider.notifier).refresh();
              ref.invalidate(sellerStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/umkm/profile'),
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const DashboardSkeleton(),
        error: (error, stack) {
          String errorMessage = 'Terjadi kesalahan saat memuat dasbor. Silakan coba kembali.';
          if (error is DioException) {
            if (error.response?.statusCode == 404) {
              errorMessage = 'Dashboard Penjual belum dapat dimuat, silakan coba kembali';
            } else {
              errorMessage = 'Gagal terhubung ke server (${error.response?.statusCode ?? "koneksi"}). Silakan coba lagi.';
            }
          } else if (error.toString().contains('404')) {
            errorMessage = 'Dashboard Penjual belum dapat dimuat, silakan coba kembali';
          }
          return ErrorStateWidget(
            errorMessage: errorMessage,
            onRetry: () {
              ref.read(sellerDashboardControllerProvider.notifier).refresh();
              ref.invalidate(sellerStatsProvider);
            },
          );
        },
        data: (dashboard) {
          final stats = dashboard.stats;
          final store = dashboard.storeInfo;

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(sellerDashboardControllerProvider.notifier).refresh();
              ref.invalidate(sellerStatsProvider);
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                // Store Header info
                StoreHeader(
                  businessName: store.businessName,
                  description: store.description,
                  address: store.address,
                  phone: store.phone,
                  status: store.status,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Revenue overview Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryActive],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppElevation.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pendapatan Bulan Ini',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.onDark.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.monetization_on_outlined,
                            color: AppColors.onDark,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Rp ${stats.monthlyEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.onDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hari Ini: Rp ${stats.todayEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.onDark.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '${stats.totalOrders} Transaksi',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.onDark,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Grid Stats (Quick Statistics)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.45,
                  children: [
                    DashboardCard(
                      title: 'Produk Aktif',
                      value: '${stats.totalProducts}',
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.blue,
                    ),
                    DashboardCard(
                      title: 'Pesanan Baru',
                      value: '${stats.newOrdersCount}',
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppColors.warning,
                      subtitle: stats.newOrdersCount > 0 ? 'Perlu diproses!' : 'Semua diproses',
                    ),
                    DashboardCard(
                      title: 'Total Terjual',
                      value: '${stats.productsSold}',
                      icon: Icons.local_mall_outlined,
                      iconColor: AppColors.success,
                    ),
                    DashboardCard(
                      title: 'Rating Toko',
                      value: stats.storeRating > 0
                          ? stats.storeRating.toStringAsFixed(1)
                          : '-',
                      icon: Icons.star_border_rounded,
                      iconColor: Colors.orange,
                      subtitle: stats.storeRating > 0 ? 'Sangat bagus' : 'Belum ada ulasan',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Shortcuts grid
                Text(
                  'Menu Navigasi Toko',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ShortcutButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Produk',
                        color: Colors.blue,
                        onTap: () => context.push('/umkm/products'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ShortcutButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Pesanan',
                        color: AppColors.primary,
                        onTap: () => context.push('/umkm/orders'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ShortcutButton(
                        icon: Icons.inventory_outlined,
                        label: 'Stok Barang',
                        color: Colors.teal,
                        onTap: () => context.push('/umkm/inventory'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Statistics Weekly Graph
                statsState.when(
                  loading: () => const ShimmerBox(width: double.infinity, height: 160, borderRadius: 24),
                  error: (err, _) => Container(),
                  data: (dataList) {
                    if (dataList.isEmpty) return Container();
                    return StatisticCard(
                      data: dataList,
                      title: 'Performa Penjualan Mingguan',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Recent Activities Feed
                if (dashboard.recentActivities.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Terbaru',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboard.recentActivities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final act = dashboard.recentActivities[index];
                      IconData actIcon = Icons.notifications_outlined;
                      Color actColor = AppColors.muted;

                      if (act.type == 'ORDER') {
                        actIcon = Icons.shopping_basket_rounded;
                        actColor = AppColors.primary;
                      } else if (act.type == 'REVIEW') {
                        actIcon = Icons.star_rounded;
                        actColor = Colors.orange;
                      } else if (act.type == 'STOCK_WARN') {
                        actIcon = Icons.warning_amber_rounded;
                        actColor = AppColors.error;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.hairlineSoft),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: actColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(actIcon, size: 18, color: actColor),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.title,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    act.description,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.body,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM, HH:mm').format(act.timestamp),
                                    style: AppTypography.captionSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.section),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: AppElevation.soft,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
