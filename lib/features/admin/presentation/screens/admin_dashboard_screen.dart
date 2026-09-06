import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: AppColors.primary,
              ),
              label: 'Ringkasan',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(
                Icons.inventory_2_rounded,
                color: AppColors.primary,
              ),
              label: 'Barang',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
              ),
              label: 'Mitra & UMKM',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
              label: 'Pesanan & Kurir',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
              ),
              label: 'Profil Admin',
            ),
          ],
        ),
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
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Dashboard Admin Kopdes',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.ink),
            tooltip: 'Percakapan Admin',
            onPressed: () => context.push('/admin/chat'),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.ink,
            ),
            tooltip: 'Notifikasi',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminProductsProvider);
          ref.invalidate(mitraListProvider);
          ref.invalidate(adminOrdersProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Welcome Banner Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryActive],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
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
                          'KOPERASI DESA DIGITAL',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.nature_people_rounded,
                        color: AppColors.onPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Selamat datang,',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.onPrimary.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name ?? 'Admin Kopdes',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kelola katalog barang, verifikasi mitra UMKM, dan atur alur pengiriman desa.',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Metric Stats Header
            Text(
              'Statistik Sistem',
              style: AppTypography.caption.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: AdminStatCard(
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
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AdminStatCard(
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
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AdminStatCard(
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
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AdminStatCard(
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
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Moderation & Action Alert Notice if any pending items
            mitraAsync.maybeWhen(
              data: (mitras) {
                final pendingCount = mitras
                    .where((m) => m.status == 'PENDING_VERIFICATION')
                    .length;
                if (pendingCount == 0) return const SizedBox.shrink();

                return Column(
                  children: [
                    AdminCard(
                      borderColor: AppColors.warning,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning.withOpacity(0.08),
                          AppColors.canvas,
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              color: AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Ada $pendingCount pendaftaran mitra UMKM baru menunggu verifikasi Anda.',
                                  style: AppTypography.captionSmall,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => onNavigateTab(2),
                            child: Text(
                              'Tinjau',
                              style: AppTypography.buttonSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Quick Access Grid
            Text(
              'Akses Pintas Pengelolaan',
              style: AppTypography.caption.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
            const SizedBox(height: AppSpacing.section),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSpacing.base),
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
            child: Icon(icon, color: color, size: 22),
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
              fontSize: 11,
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
      length: 2,
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
            tabs: const [
              Tab(text: 'Verifikasi Mitra'),
              Tab(text: 'Moderasi Produk'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MitraManagementScreenContent(),
            UmkmProductTakedownScreenContent(),
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
