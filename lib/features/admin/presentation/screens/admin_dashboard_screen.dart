import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/screens/conversation_list_screen.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../umkm/data/store_scope.dart';
import '../../../umkm/presentation/controllers/store_controller.dart';
import '../../../umkm/presentation/screens/product_screen.dart';
import '../../../umkm/presentation/screens/store_profile_screen.dart';
import '../../../umkm/presentation/widgets/seller_dashboard_sections.dart';
import '../../../umkm/presentation/widgets/seller_header.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/kopdes_console.dart';
import 'courier_management_screen.dart';
import 'order_management_screen.dart';

/// Konsol pengurus Kopdes — kerangka yang sama dengan konsol penjual UMKM.
///
/// Dasbor, Produk, Pesanan, Pesan, dan Koperasi. Halaman Produk dan tab
/// Koperasi adalah halaman milik penjual yang sama persis; [storeScopeProvider]
/// memilih alamat API Kopdes untuk akun pengurus. Menu khas pengurus (mitra,
/// pencairan, pegawai, kurir) dikumpulkan di tab Koperasi.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const AdminDashboardScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late int _currentIndex = widget.initialIndex;

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _KopdesOverviewTab(onNavigateTab: _onTabSelected),
          const ProductScreen(),
          const _OrdersAndCouriersTab(),
          const ConversationListScreen(channel: ChatChannel.general),
          const StoreProfileScreen(),
        ],
      ),
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
            label: 'Koperasi',
            icon: Icons.account_balance_outlined,
            activeIcon: Icons.account_balance_rounded,
          ),
        ],
        activeIndex: _currentIndex,
        onSelect: _onTabSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 0: DASBOR
// ─────────────────────────────────────────────────────────
class _KopdesOverviewTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const _KopdesOverviewTab({required this.onNavigateTab});

  /// Lebar isi maksimum, sama dengan dasbor penjual.
  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatCount = ref
        .watch(conversationsProvider)
        .maybeWhen(
          data: (items) => items.fold<int>(0, (t, c) => t + c.unreadCount),
          orElse: () => 0,
        );
    final unread = ref.watch(unreadNotificationCountProvider);
    final profile = ref.watch(storeProfileProvider).valueOrNull;
    final dashboard = ref.watch(kopdesDashboardProvider);
    final newProduct = ref.watch(storeScopeProvider).newProductRoute;

    Future<void> refresh() async {
      ref.invalidate(kopdesDashboardProvider);
      ref.invalidate(storeProfileProvider);
      try {
        await ref.read(kopdesDashboardProvider.future);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerHeader(
            storeName: profile?.businessName ?? 'Kopdes',
            statusLabel: switch (profile?.isOpen) {
              true => 'Kopdes buka · melayani pesanan',
              false => 'Kopdes sedang tutup',
              null => 'Jam buka belum diatur',
            },
            isVerified: profile?.isVerified ?? false,
            newOrderCount: dashboard.valueOrNull?.stats.newOrdersCount ?? 0,
            chatCount: chatCount,
            notificationCount: unread,
            onOrdersTap: () => onNavigateTab(2),
            onChatTap: () => onNavigateTab(3),
            onNotificationTap: () => context.push('/notifications'),
            onSearchTap: () => onNavigateTab(1),
            onAddProductTap: () => context.push(newProduct),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: refresh,
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = c.maxWidth > _maxContentWidth
                      ? (c.maxWidth - _maxContentWidth) / 2
                      : 0.0;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.base + side,
                      AppSpacing.md,
                      AppSpacing.base + side,
                      112,
                    ),
                    children: [
                      // Hanya kartu angka yang bergantung pada dasbor;
                      // aksi cepat tetap bisa dipakai saat API lambat.
                      dashboard.when(
                        skipLoadingOnRefresh: true,
                        loading: () => const SectionSkeleton(height: 168),
                        error: (e, _) => SectionError(
                          message:
                              'Ringkasan penjualan belum termuat. '
                              '${networkErrorMessage(e)}',
                          onRetry: () =>
                              ref.invalidate(kopdesDashboardProvider),
                        ),
                        data: (d) => SalesSummaryCard(stats: d.stats),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      QuickActionsRow(
                        actions: [
                          SellerQuickAction(
                            icon: Icons.add_business_outlined,
                            label: 'Tambah Produk',
                            onTap: () => context.push(newProduct),
                          ),
                          SellerQuickAction(
                            icon: Icons.receipt_long_outlined,
                            label: 'Pesanan',
                            onTap: () => onNavigateTab(2),
                          ),
                          SellerQuickAction(
                            icon: Icons.verified_user_outlined,
                            label: 'Mitra',
                            onTap: () => context
                                .push('/admin/mitra')
                                .then(
                                  (_) =>
                                      ref.invalidate(kopdesDashboardProvider),
                                ),
                          ),
                          SellerQuickAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Keuangan',
                            onTap: () => context.push('/pegawai/keuangan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...dashboard.maybeWhen(
                        skipLoadingOnRefresh: true,
                        data: (d) => [
                          AttentionSection(
                            onSeeAll: () => onNavigateTab(2),
                            items: [
                              AttentionItem(
                                icon: Icons.receipt_long_outlined,
                                tint: AppColors.primary,
                                title: 'Pesanan baru',
                                urgentMessage: 'Menunggu diproses',
                                calmMessage: 'Tidak ada pesanan yang menunggu',
                                count: d.stats.newOrdersCount,
                                onTap: () => onNavigateTab(2),
                              ),
                              AttentionItem(
                                icon: Icons.warning_amber_rounded,
                                tint: AppColors.warning,
                                title: 'Stok menipis',
                                urgentMessage: 'Segera tambah stok barang',
                                calmMessage: 'Stok barang aman',
                                count: d.stats.lowStockCount,
                                onTap: () => onNavigateTab(1),
                              ),
                              AttentionItem(
                                icon: Icons.hourglass_top_rounded,
                                tint: AppColors.success,
                                title: 'Pendaftaran mitra',
                                urgentMessage: 'Menunggu verifikasi Anda',
                                calmMessage: 'Tidak ada pendaftaran baru',
                                count: d.pendingMitra,
                                onTap: () => context
                                    .push('/admin/mitra')
                                    .then(
                                      (_) => ref.invalidate(
                                        kopdesDashboardProvider,
                                      ),
                                    ),
                              ),
                              AttentionItem(
                                icon: Icons.payments_outlined,
                                tint: const Color(0xFF2F6FDB),
                                title: 'Pencairan mitra',
                                urgentMessage: 'Menunggu ditransfer',
                                calmMessage: 'Tidak ada permintaan pencairan',
                                count: d.pendingPayouts,
                                onTap: () => context
                                    .push('/admin/payouts')
                                    .then(
                                      (_) => ref.invalidate(
                                        kopdesDashboardProvider,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          StoreSummaryGrid(
                            cells: [
                              StoreSummaryCell(
                                icon: Icons.inventory_2_outlined,
                                tint: AppColors.success,
                                label: 'Produk Aktif',
                                value: '${d.stats.totalProducts}',
                              ),
                              StoreSummaryCell(
                                icon: Icons.shopping_bag_outlined,
                                tint: AppColors.primary,
                                label: 'Terjual',
                                value: '${d.stats.productsSold}',
                              ),
                              StoreSummaryCell(
                                icon: Icons.star_outline_rounded,
                                tint: AppColors.warning,
                                label: 'Rating Kopdes',
                                value: d.stats.storeRating > 0
                                    ? d.stats.storeRating
                                          .toStringAsFixed(1)
                                          .replaceAll('.', ',')
                                    : '—',
                                note: d.stats.storeRating > 0
                                    ? null
                                    : 'Belum ada ulasan',
                              ),
                              StoreSummaryCell(
                                icon: Icons.receipt_outlined,
                                tint: AppColors.primary,
                                label: 'Total Pesanan',
                                value: '${d.stats.totalOrders}',
                              ),
                            ],
                          ),
                        ],
                        orElse: () => const [],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StoreTipsRow(
                        actionLabel: 'Lengkapi Profil',
                        onTap: () => onNavigateTab(4),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 2: PESANAN & PENGANTARAN
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
          automaticallyImplyLeading: false,
          title: Text(
            'Pesanan & Pengantaran',
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
