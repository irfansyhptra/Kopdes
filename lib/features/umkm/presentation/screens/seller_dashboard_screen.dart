import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/network/error_message.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../widgets/seller_dashboard_sections.dart';
import '../widgets/seller_header.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../data/models/seller_model.dart';
import 'product_screen.dart';
import 'order_screen.dart';
import '../../../chat/presentation/screens/conversation_list_screen.dart';
import 'store_profile_screen.dart';

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
              // pendapatan Rp2.450.000. Angka karangan di dasbor penjual
              // lebih buruk daripada layar error: pemiliknya mengambil
              // keputusan dagang dari angka itu.
              error: (error, _) => _LoadFailed(
                message: networkErrorMessage(error),
                onRetry: () {
                  ref
                      .read(sellerDashboardControllerProvider.notifier)
                      .refresh();
                  ref.invalidate(sellerStatsProvider);
                },
              ),
              data: (dashboard) => _OverviewBody(
                dashboard: dashboard,
                onNavigateTab: onNavigateTab,
              ),
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
}

/// Isi dasbor di antara kepala halaman dan bilah navigasi.
///
/// `CustomScrollView`: tiap bagian adalah slivernya sendiri, jadi daftar
/// panjang di masa depan bisa ditambahkan tanpa membungkus ulang semuanya.
/// Lebarnya dijepit di tablet — dasbor selebar 1024dp membuat satu baris
/// angka terentang sampai sulit dipindai.
class _OverviewBody extends ConsumerWidget {
  final SellerModel dashboard;
  final ValueChanged<int> onNavigateTab;

  const _OverviewBody({required this.dashboard, required this.onNavigateTab});

  /// Lebar isi maksimum. Di atas ini kolomnya dipusatkan.
  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = dashboard.stats;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(sellerDashboardControllerProvider.notifier).refresh();
        ref.invalidate(sellerStatsProvider);
      },
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth > _maxContentWidth
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 0.0;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.base + side,
                  AppSpacing.md,
                  AppSpacing.base + side,
                  // Ruang untuk bilah navigasi mengambang.
                  112,
                ),
                sliver: SliverList.list(
                  children: [
                    SalesSummaryCard(stats: stats),
                    const SizedBox(height: AppSpacing.md),

                    QuickActionsRow(
                      actions: [
                        SellerQuickAction(
                          icon: Icons.add_business_outlined,
                          label: 'Tambah Produk',
                          onTap: () => context.push('/umkm/products/new'),
                        ),
                        SellerQuickAction(
                          icon: Icons.receipt_long_outlined,
                          label: 'Pesanan',
                          onTap: () => onNavigateTab(2),
                        ),
                        SellerQuickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stok',
                          // Kendali stok melebur ke halaman Produk; tidak ada
                          // lagi halaman stok tersendiri untuk dituju.
                          onTap: () => onNavigateTab(1),
                        ),
                        SellerQuickAction(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Keuangan',
                          // Saldo dompet toko tinggal di halaman Toko.
                          onTap: () => onNavigateTab(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AttentionSection(
                      onSeeAll: () => onNavigateTab(2),
                      items: [
                        AttentionItem(
                          icon: Icons.receipt_long_outlined,
                          tint: AppColors.primary,
                          title: 'Pesanan baru',
                          urgentMessage: 'Menunggu diproses',
                          calmMessage: 'Tidak ada pesanan yang menunggu',
                          count: stats.newOrdersCount,
                          onTap: () => onNavigateTab(2),
                        ),
                        AttentionItem(
                          icon: Icons.warning_amber_rounded,
                          tint: AppColors.warning,
                          title: 'Stok menipis',
                          urgentMessage: 'Segera tambah stok produk Anda',
                          calmMessage: 'Stok produk aman',
                          count: stats.lowStockCount,
                          onTap: () => onNavigateTab(1),
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
                          value: '${stats.totalProducts}',
                        ),
                        StoreSummaryCell(
                          icon: Icons.shopping_bag_outlined,
                          tint: AppColors.primary,
                          label: 'Terjual',
                          value: '${stats.productsSold}',
                        ),
                        StoreSummaryCell(
                          icon: Icons.star_outline_rounded,
                          tint: AppColors.warning,
                          label: 'Rating Toko',
                          // Garis, bukan 0,0: rentang penilaian 1–5, jadi
                          // nol bukan nilai yang pernah bisa diberikan.
                          value: stats.storeRating > 0
                              ? stats.storeRating
                                    .toStringAsFixed(1)
                                    .replaceAll('.', ',')
                              : '—',
                          note: stats.storeRating > 0
                              ? null
                              : 'Belum ada ulasan',
                        ),
                        const StoreSummaryCell(
                          icon: Icons.bar_chart_rounded,
                          tint: AppColors.primary,
                          label: 'Kunjungan Toko',
                          // Backend belum menghitung kunjungan sama sekali.
                          // Garis, bukan angka rekaan.
                          value: '—',
                          note: 'Belum ada data',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    StoreTipsRow(
                      actionLabel: 'Lengkapi Profil',
                      // Tidak ada halaman tips: tabel ContentPage kosong dan
                      // `/info/:slug` akan mendarat di halaman gagal. Yang
                      // ditawarkan adalah tujuan yang benar-benar ada, dan
                      // labelnya menyebut apa yang sebenarnya terjadi.
                      onTap: () => onNavigateTab(4),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
