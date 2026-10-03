import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/dashboard_card.dart';
import '../../../../shared/components/statistic_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../core/network/error_message.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../widgets/seller_header.dart';
import '../widgets/seller_page_ui.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../data/models/seller_model.dart';
import 'product_screen.dart';
import 'order_screen.dart';
import '../../../chat/presentation/screens/conversation_list_screen.dart';
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
          // Pesan menggantikan tab Stok: kendali stok kini ada di dalam
          // kartu produk, dan yang tidak punya tempat justru percakapan
          // dengan pembeli — selama ini hanya bisa dicapai lewat satu ikon
          // kecil di kepala halaman.
          const ConversationListScreen(),
          const StoreProfileScreen(),
        ],
      ),
      // Bilahnya mengambang, jadi isi boleh lewat di belakangnya.
      extendBody: true,
      bottomNavigationBar: AppGlassNavBar(
        items: const [
          GlassNavItem(
            label: 'Dasbor',
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
          ),
          GlassNavItem(
            label: 'Produk',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
          ),
          GlassNavItem(
            label: 'Pesanan',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
          GlassNavItem(
            label: 'Pesan',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
          ),
          GlassNavItem(
            label: 'Toko',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
          ),
        ],
        activeIndex: _currentIndex,
        onSelect: _onTabSelected,
      ),
    );
  }
}

/// Dasbor yang gagal dimuat — tanpa angka pengganti.
class _LoadFailed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailed({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Data toko belum berhasil dimuat',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
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

    final chatCount = ref
        .watch(conversationsProvider)
        .maybeWhen(
          data: (items) => items.fold<int>(
            0,
            (total, conversation) => total + conversation.unreadCount,
          ),
          orElse: () => 0,
        );
    final unread = ref.watch(unreadNotificationCountProvider);
    final store = dashboardState.valueOrNull?.storeInfo;
    final newOrders = dashboardState.valueOrNull?.stats.newOrdersCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerHeader(
            storeName: store?.businessName ?? 'Toko UMKM',
            statusLabel: _statusLabel(store?.status),
            isVerified: store?.status == 'ACTIVE',
            newOrderCount: newOrders,
            chatCount: chatCount,
            notificationCount: unread,
            onOrdersTap: () => onNavigateTab(2),
            onChatTap: () => onNavigateTab(3),
            onNotificationTap: () => context.push('/notifications'),
            onSearchTap: () => onNavigateTab(1),
            onAddProductTap: () => context.push('/umkm/products/new'),
          ),
          Expanded(
            child: dashboardState.when(
              loading: () =>
                  const Center(child: AppleActivityIndicator(size: 28)),
              // Dulu kegagalan di sini diganti toko contoh lengkap dengan
              // pendapatan Rp2.450.000 dan 12 transaksi. Angka karangan di
              // dasbor penjual lebih buruk daripada layar error: pemiliknya
              // mengambil keputusan dagang dari angka itu.
              error: (error, _) => _LoadFailed(
                message: networkErrorMessage(error),
                onRetry: () {
                  ref
                      .read(sellerDashboardControllerProvider.notifier)
                      .refresh();
                  ref.invalidate(sellerStatsProvider);
                },
              ),
              data: (dashboard) =>
                  _buildDashboardContent(context, ref, dashboard, statsState),
            ),
          ),
        ],
      ),
    );
  }

  /// Status toko dalam kalimat warga, bukan konstanta basis data.
  static String _statusLabel(String? status) => switch (status) {
    'ACTIVE' => 'Toko aktif · melayani pesanan',
    'PENDING_VERIFICATION' => 'Menunggu verifikasi pengurus Kopdes',
    'REJECTED' => 'Pendaftaran ditolak',
    'SUSPENDED' => 'Toko ditangguhkan',
    _ => 'Status toko belum diketahui',
  };

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    SellerModel dashboard,
    AsyncValue<List<dynamic>> statsState,
  ) {
    final stats = dashboard.stats;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(sellerDashboardControllerProvider.notifier).refresh();
        ref.invalidate(sellerStatsProvider);
      },
      color: AppColors.primary,
      child: SellerContentBoundary(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.base, 0, 112),
          children: [
            AppleCard(
              onTap: () => context.push('/umkm/products/new'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
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
                          'Tambah produk baru',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Lengkapi foto, harga, dan stok untuk mulai berjualan.',
                          style: AppTypography.captionSmall.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Revenue Overview Card
            AppleCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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
            // Tinggi dalam piksel, bukan rasio: rasio mengikat tinggi pada
            // lebar, sehingga kartu yang sama meluber di layar sempit dan
            // menyisakan lubang kosong di tablet.
            LayoutBuilder(
              builder: (context, constraints) => GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 720 ? 4 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: dashboardTileHeight(context),
                ),
                children: [
                  DashboardCard(
                    title: 'Produk Aktif',
                    value: '${stats.totalProducts}',
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primary,
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
                    iconColor: AppColors.warning,
                    subtitle: stats.storeRating > 0
                        ? 'Sangat bagus'
                        : 'Belum ada ulasan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features Navigation Shortcuts Grid
            const AppleSectionHeader(title: 'Fitur Penjualan Utama'),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) => GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 720 ? 4 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: featureTileHeight(context),
                ),
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
                    color: AppColors.primary,
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
                    color: AppColors.warning,
                    onTap: () => onNavigateTab(3),
                  ),
                ],
              ),
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
                    actColor = AppColors.warning;
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
                            color: actColor.withValues(alpha: 0.1),
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
                                DateFormat(
                                  'dd MMM, HH:mm',
                                ).format(act.timestamp),
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
                color: color.withValues(alpha: 0.12),
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
