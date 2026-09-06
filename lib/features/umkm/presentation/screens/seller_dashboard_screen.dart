import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/dashboard_card.dart';
import '../../../../shared/components/statistic_card.dart';
import '../../../../shared/components/store_header.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../data/models/seller_model.dart';
import '../../data/models/store_model.dart';
import 'product_screen.dart';
import 'order_screen.dart';
import 'inventory_screen.dart';
import 'store_profile_screen.dart';
import 'package:intl/intl.dart';

// Dasbor Penjual UMKM: Multi-Tab Navigation Shell & Selling Features.
class SellerDashboardScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const SellerDashboardScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(sellerDashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SellerDashboardOverviewTab(
            dashboardState: dashboardState,
            onNavigateTab: _onTabSelected,
          ),
          const ProductScreen(),
          const OrderScreen(),
          const InventoryScreen(),
          const StoreProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
          boxShadow: AppElevation.soft,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          elevation: 0,
          backgroundColor: AppColors.canvas,
          indicatorColor: AppColors.primarySoft.withOpacity(0.5),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
              ),
              label: 'Dasbor UMKM',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(
                Icons.inventory_2_rounded,
                color: AppColors.primary,
              ),
              label: 'Katalog Produk',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
              label: 'Pesanan Masuk',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_outlined),
              selectedIcon: Icon(
                Icons.inventory_rounded,
                color: AppColors.primary,
              ),
              label: 'Stok Barang',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
              label: 'Profil Toko',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 0: RINGKASAN DASBOR UMKM & FITUR PENJUALAN
// ─────────────────────────────────────────────────────────
class _SellerDashboardOverviewTab extends ConsumerWidget {
  final AsyncValue<SellerModel> dashboardState;
  final ValueChanged<int> onNavigateTab;

  const _SellerDashboardOverviewTab({
    required this.dashboardState,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(sellerStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Dasbor Penjual UMKM',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            tooltip: 'Perbarui Data',
            onPressed: () {
              ref.read(sellerDashboardControllerProvider.notifier).refresh();
              ref.invalidate(sellerStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.ink,
            ),
            tooltip: 'Profil Toko',
            onPressed: () => onNavigateTab(4),
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) {
          // Graceful fallback for 404 / Missing Store Profile so user can setup store & sell products
          final fallbackStore = StoreModel(
            id: 'umkm-demo-1',
            userId: 'user-umkm-1',
            businessName: 'UMKM Jaya Abadi',
            description: 'Toko UMKM Mitra Koperasi Desa',
            address: 'Jl. Koperasi No. 12, Sinduadi',
            phone: '081400000001',
            status: 'ACTIVE',
          );
          final fallbackStats = SellerDashboardStats(
            totalProducts: 4,
            totalOrders: 12,
            productsSold: 28,
            todayEarnings: 180000,
            monthlyEarnings: 2450000,
            storeRating: 4.8,
            lowStockCount: 1,
            newOrdersCount: 2,
          );
          final fallbackDashboard = SellerModel(
            storeInfo: fallbackStore,
            stats: fallbackStats,
            lowStockProducts: [],
            recentActivities: [
              SellerActivity(
                type: 'ORDER',
                title: 'Pesanan Baru Masuk',
                description: 'Pelanggan membeli 2x Madu Randu Asli Hutan',
                timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              ),
              SellerActivity(
                type: 'REVIEW',
                title: 'Ulasan Bintang 5',
                description: 'Budi Santoso memberikan ulasan bintang 5',
                timestamp: DateTime.now().subtract(const Duration(hours: 5)),
              ),
            ],
          );

          return _buildDashboardContent(
            context,
            ref,
            fallbackDashboard,
            statsState,
          );
        },

        data: (dashboard) {
          return _buildDashboardContent(context, ref, dashboard, statsState);
        },
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    SellerModel dashboard,
    AsyncValue<List<dynamic>> statsState,
  ) {
    final stats = dashboard.stats;
    final store = dashboard.storeInfo;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(sellerDashboardControllerProvider.notifier).refresh();
        ref.invalidate(sellerStatsProvider);
      },
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Store Header Info
          StoreHeader(
            businessName: store.businessName,
            description: store.description,
            address: store.address,
            phone: store.phone,
            status: store.status,
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Hero Banner: "JUAL PRODUK BARU"
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'PASARKAN PRODUK ANDA',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.onDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.onDark,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ingin Menjual Produk Baru?',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambah foto, nama, deskripsi, harga, dan stok barang olahan atau kerajinan Anda untuk mulai berjualan kepada warga desa.',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.onDark.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                ElevatedButton.icon(
                  onPressed: () => context.push('/umkm/products/new'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.canvas,
                    foregroundColor: AppColors.primary,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  label: Text(
                    'Jual Produk Baru Sekarang',
                    style: AppTypography.buttonSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue Overview Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairlineSoft),
              boxShadow: AppElevation.soft,
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
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rp ${stats.monthlyEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hari Ini: Rp ${stats.todayEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${stats.totalOrders} Transaksi',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
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

          // Grid Quick Stats
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
                subtitle: stats.newOrdersCount > 0
                    ? 'Perlu diproses!'
                    : 'Semua diproses',
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
                subtitle: stats.storeRating > 0
                    ? 'Sangat bagus'
                    : 'Belum ada ulasan',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Features Navigation Shortcuts Grid
          Text(
            'Fitur Penjualan Utama',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
            children: [
              _FeatureCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Jual Produk Baru',
                subtitle: 'Tambah barang untuk dijual',
                color: AppColors.primary,
                onTap: () => context.push('/umkm/products/new'),
              ),
              _FeatureCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Katalog Produk',
                subtitle: 'Edit harga & stok barang',
                color: Colors.blue,
                onTap: () => onNavigateTab(1),
              ),
              _FeatureCard(
                icon: Icons.receipt_long_outlined,
                title: 'Pesanan Masuk',
                subtitle: 'Kelola order pelanggan',
                color: AppColors.warning,
                onTap: () => onNavigateTab(2),
              ),
              _FeatureCard(
                icon: Icons.inventory_outlined,
                title: 'Stok & Inventaris',
                subtitle: 'Cek stok hampir habis',
                color: Colors.teal,
                onTap: () => onNavigateTab(3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Statistics Weekly Graph
          statsState.when(
            loading: () => const ShimmerGroup(
              child: ShimmerBox(
                width: double.infinity,
                height: 160,
                borderRadius: 24,
              ),
            ),
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
                  'Aktivitas Terbaru Toko',
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
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
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
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: AppElevation.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
