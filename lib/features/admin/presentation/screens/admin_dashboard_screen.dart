import 'package:flutter/material.dart';
import 'payout_queue_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../product/presentation/screens/admin/admin_product_list_screen.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';
import 'mitra_management_screen.dart';
import 'umkm_product_takedown_screen.dart';
import 'order_management_screen.dart';
import 'courier_management_screen.dart';
import 'admin_profile_screen.dart';

// Multi-tab Dashboard Admin Kopdes dengan Bottom Navigation Bar.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const AdminDashboardScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _AdminOverviewTab(onNavigateTab: _onTabSelected),
          const AdminProductListScreen(showBackButton: false),
          const _MitraAndUmkmTab(),
          const _OrdersAndCouriersTab(),
          const AdminProfileScreen(),
        ],
      ),
      // Bilahnya mengambang, jadi isi boleh lewat di belakangnya.
      extendBody: true,
      bottomNavigationBar: AppGlassNavBar(
        items: const [
          GlassNavItem(
            label: 'Ringkasan',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          GlassNavItem(
            label: 'Barang',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
          ),
          GlassNavItem(
            label: 'Mitra',
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
          ),
          GlassNavItem(
            label: 'Pesanan',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
          GlassNavItem(
            label: 'Profil',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
        activeIndex: _currentIndex,
        onSelect: _onTabSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 0: RINGKASAN (OVERVIEW DASHBOARD)
// ─────────────────────────────────────────────────────────
class _AdminOverviewTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const _AdminOverviewTab({required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final productsAsync = ref.watch(adminProductsProvider);
    final mitraAsync = ref.watch(mitraListProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          GlassPageHeader(
            title: 'Dashboard Kopdes',
            subtitle: 'Selamat bekerja, ${user?.name ?? 'Admin Kopdes'}',
            actions: [
              GlassIconButton(
                icon: Icons.forum_outlined,
                label: 'Percakapan Admin',
                onDark: true,
                onTap: () => context.push('/admin/chat'),
              ),
              GlassIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi',
                onDark: true,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(adminProductsProvider);
                ref.invalidate(mitraListProvider);
                ref.invalidate(adminOrdersProvider);
              },
              child: AppleContentBoundary(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.base,
                    0,
                    112,
                  ),
                  children: [
                    AppleSection(
                      title: 'Statistik Sistem',
                      child: AppleResponsiveGrid(
                        minimumItemWidth: 128,
                        maxColumns: 4,
                        itemExtentBuilder: (context, _) {
                          final scale =
                              MediaQuery.textScalerOf(context).scale(14) / 14;
                          return 128 + 64 * (scale.clamp(1.0, 2.0) - 1);
                        },
                        children: [
                          AdminStatCard(
                            title: 'Barang Ritel',
                            value: productsAsync.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            subtitle: productsAsync.when(
                              data: (list) =>
                                  '${list.where((p) => p.isActive).length} Aktif',
                              loading: () => '',
                              error: (_, __) => '',
                            ),
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            onTap: () => onNavigateTab(1),
                          ),
                          AdminStatCard(
                            title: 'Mitra UMKM',
                            value: mitraAsync.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            subtitle: mitraAsync.when(
                              data: (list) =>
                                  '${list.where((m) => m.status == 'PENDING_VERIFICATION').length} Menunggu',
                              loading: () => '',
                              error: (_, __) => '',
                            ),
                            icon: Icons.storefront_outlined,
                            color: AppColors.success,
                            onTap: () => onNavigateTab(2),
                          ),
                          AdminStatCard(
                            title: 'Pesanan Masuk',
                            value: ordersAsync.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            subtitle: ordersAsync.when(
                              data: (list) =>
                                  '${list.where((o) => o.status == 'PENDING' || o.status == 'PAID').length} Perlu Proses',
                              loading: () => '',
                              error: (_, __) => '',
                            ),
                            icon: Icons.receipt_long_outlined,
                            color: AppColors.warning,
                            onTap: () => onNavigateTab(3),
                          ),
                          AdminStatCard(
                            title: 'Omzet Koperasi',
                            value: ordersAsync.when(
                              data: (list) {
                                final total = list.fold<num>(
                                  0,
                                  (sum, item) => sum + item.totalAmount,
                                );
                                return rupiah(total);
                              },
                              loading: () => '...',
                              error: (_, __) => 'Rp 0',
                            ),
                            subtitle: 'Total akumulasi pesanan',
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.primaryActive,
                            onTap: () => onNavigateTab(3),
                          ),
                        ],
                      ),
                    ),
                    mitraAsync.maybeWhen(
                      data: (mitras) {
                        final pendingCount = mitras
                            .where((m) => m.status == 'PENDING_VERIFICATION')
                            .length;
                        if (pendingCount == 0) {
                          return const SizedBox(height: AppSpacing.base);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.base,
                          ),
                          child: _ModerationNotice(
                            count: pendingCount,
                            onTap: () => onNavigateTab(2),
                          ),
                        );
                      },
                      orElse: () => const SizedBox(height: AppSpacing.base),
                    ),
                    AppleSection(
                      title: 'Akses Pintas Pengelolaan',
                      child: AppleResponsiveGrid(
                        minimumItemWidth: 128,
                        maxColumns: 4,
                        itemExtentBuilder: (context, _) {
                          final scale =
                              MediaQuery.textScalerOf(context).scale(14) / 14;
                          return 124 + 72 * (scale.clamp(1.0, 2.0) - 1);
                        },
                        children: [
                          _QuickShortcutCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'Kelola Barang Ritel',
                            subtitle: 'Tambah & edit stok produk',
                            color: AppColors.primary,
                            onTap: () => onNavigateTab(1),
                          ),
                          _QuickShortcutCard(
                            icon: Icons.verified_user_outlined,
                            title: 'Pengelolaan Mitra',
                            subtitle: 'Verifikasi & kelola UMKM',
                            color: AppColors.success,
                            onTap: () => onNavigateTab(2),
                          ),
                          _QuickShortcutCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Pesanan Masuk',
                            subtitle: 'Ubah status order',
                            color: AppColors.warning,
                            onTap: () => onNavigateTab(3),
                          ),
                          _QuickShortcutCard(
                            icon: Icons.local_shipping_outlined,
                            title: 'Penugasan Kurir',
                            subtitle: 'Atur pengantaran barang',
                            color: AppColors.primaryActive,
                            onTap: () => onNavigateTab(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationNotice extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ModerationNotice({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.warning,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verifikasi Mitra UMKM',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count pendaftaran baru menunggu peninjauan.',
                  style: AppTypography.captionSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedSoft),
        ],
      ),
    );
  }
}

class _QuickShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 2: MITRA & MODERASI TAB
// ─────────────────────────────────────────────────────────
class _MitraAndUmkmTab extends StatelessWidget {
  const _MitraAndUmkmTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          title: Text(
            'Mitra & Moderasi UMKM',
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Verifikasi Mitra'),
              Tab(text: 'Moderasi Produk'),
              Tab(text: 'Pencairan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MitraManagementScreenContent(),
            UmkmProductTakedownScreenContent(),
            PayoutQueueScreen(),
          ],
        ),
      ),
    );
  }
}

// Sub-content wrapper for Mitra Management inside Dashboard Shell
class MitraManagementScreenContent extends StatelessWidget {
  const MitraManagementScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const MitraManagementScreen();
  }
}

// Sub-content wrapper for UMKM Product Takedown inside Dashboard Shell
class UmkmProductTakedownScreenContent extends StatelessWidget {
  const UmkmProductTakedownScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const UmkmProductTakedownScreen();
  }
}

// ─────────────────────────────────────────────────────────
// TAB 3: PESANAN & KURIR TAB
// ─────────────────────────────────────────────────────────
class _OrdersAndCouriersTab extends StatelessWidget {
  const _OrdersAndCouriersTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          title: Text(
            'Pesanan & Kurir Koperasi',
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
              Tab(text: 'Pesanan Masuk'),
              Tab(text: 'Kurir & Pengantaran'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [OrderManagementScreen(), CourierManagementScreen()],
        ),
      ),
    );
  }
}
