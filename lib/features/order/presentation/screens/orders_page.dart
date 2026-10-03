import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/order_status_view.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/orders_page_provider.dart';
import '../widgets/cart_seller_group.dart';
import '../widgets/order_status_card.dart';
import '../widgets/orders_chrome.dart';
import '../widgets/orders_responsive.dart';
import '../widgets/shopping_summary.dart';

/// Halaman Pesanan: keranjang, pesanan berjalan, dan riwayat dalam satu tempat.
///
/// Menggantikan `CartScreen` pada tab Pesanan. Layar lama hanya menampilkan
/// keranjang di balik header merah setinggi seperempat layar, dan riwayat
/// pesanan hanya bisa dicapai lewat rute terpisah `/orders/history` — dua
/// tempat untuk satu pertanyaan yang sama: "pesanan saya bagaimana".
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  bool _summaryInitialised = false;

  Future<void> _refresh() async {
    final tab = ref.read(ordersTabProvider);
    // Menyegarkan hanya yang sedang dilihat: menarik keranjang tidak perlu
    // ikut memuat ulang riwayat pesanan.
    if (tab == OrdersTab.cart) {
      await ref.read(cartProvider.notifier).loadCart();
    } else {
      await ref.read(orderHistoryProvider.notifier).load();
    }
  }

  void _goCheckout() => context.push('/checkout');

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(ordersTabProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = OrdersSpec.fromWidth(constraints.maxWidth);

        // Ringkasan dimulai terlipat pada layar pendek, tetapi hanya sekali:
        // setelah itu keputusan melipat atau membuka adalah milik pengguna.
        if (!_summaryInitialised && !spec.splitLayout) {
          _summaryInitialised = true;
          final viewport = MediaQuery.sizeOf(context);
          if (OrdersSpec.shouldCollapseSummary(viewport)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(summaryExpandedProvider.notifier).state = false;
              }
            });
          }
        }

        final showSummary = tab == OrdersTab.cart;

        return Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: spec.contentMaxWidth),
                child: spec.splitLayout
                    ? _SplitBody(
                        spec: spec,
                        showSummary: showSummary,
                        onRefresh: _refresh,
                        onCheckout: _goCheckout,
                      )
                    : _StackedBody(
                        spec: spec,
                        showSummary: showSummary,
                        onRefresh: _refresh,
                        onCheckout: _goCheckout,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ponsel: satu kolom, ringkasan mengambang di atas bilah navigasi.
class _StackedBody extends ConsumerWidget {
  final OrdersSpec spec;
  final bool showSummary;
  final Future<void> Function() onRefresh;
  final VoidCallback onCheckout;

  const _StackedBody({
    required this.spec,
    required this.showSummary,
    required this.onRefresh,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navHeight = CustomBottomNavBar.totalHeight(context);
    final hasItems = ref.watch(cartItemCountProvider) > 0;
    final panelVisible = showSummary && hasItems;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.canvas,
          child: _OrdersScrollView(
            spec: spec,
            // Ruang bawah dihitung dari tinggi bilah navigasi yang sebenarnya
            // ditambah perkiraan tinggi panel ringkasan — bukan satu angka
            // tetap yang akan salah begitu salah satunya berubah.
            bottomPadding: navHeight + (panelVisible ? 150 : AppSpacing.lg),
            onCheckout: onCheckout,
          ),
        ),
        if (panelVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: navHeight,
            child: ShoppingSummaryPanel(onCheckout: onCheckout),
          ),
      ],
    );
  }
}

/// Tablet dan desktop: daftar di kiri, ringkasan menempel di kanan.
class _SplitBody extends ConsumerWidget {
  final OrdersSpec spec;
  final bool showSummary;
  final Future<void> Function() onRefresh;
  final VoidCallback onCheckout;

  const _SplitBody({
    required this.spec,
    required this.showSummary,
    required this.onRefresh,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = ref.watch(cartItemCountProvider) > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.canvas,
            child: _OrdersScrollView(
              spec: spec,
              bottomPadding: CustomBottomNavBar.totalHeight(context),
              onCheckout: onCheckout,
            ),
          ),
        ),
        if (showSummary && hasItems) ...[
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: spec.summaryWidth,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                // Sejajar dengan kartu pertama di kolom kiri, di bawah header
                // dan segmented control.
                140,
                spec.pagePadding,
                AppSpacing.lg,
              ),
              child: ShoppingSummaryCard(onCheckout: onCheckout),
            ),
          ),
        ],
      ],
    );
  }
}

/// Isi yang menggulir. Sama untuk kedua tata letak; hanya ruang bawahnya beda.
class _OrdersScrollView extends ConsumerWidget {
  final OrdersSpec spec;
  final double bottomPadding;
  final VoidCallback onCheckout;

  const _OrdersScrollView({
    required this.spec,
    required this.bottomPadding,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(ordersTabProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return CustomScrollView(
      key: const PageStorageKey('orders-scroll'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: spec.pagePadding),
          sliver: SliverToBoxAdapter(
            child: OrdersHeader(
              notificationCount: unread,
              // Backend belum punya pencarian pesanan, jadi ikon ini membuka
              // pencarian produk di Marketplace — dan labelnya menyebut itu,
              // bukan berpura-pura mencari pesanan.
              onSearch: () => context.go('/products'),
              onNotifications: () => context.push('/notifications'),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: spec.pagePadding),
          sliver: const SliverToBoxAdapter(child: OrdersTabs()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.base)),

        if (tab == OrdersTab.cart)
          ..._cartSlivers(context, ref)
        else if (tab == OrdersTab.active)
          _ordersSliver(ref, ref.watch(activeOrdersProvider), finished: false)
        else
          ..._doneSlivers(ref),

        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }

  // ── Tab Keranjang ────────────────────────────────────────────

  List<Widget> _cartSlivers(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final padding = EdgeInsets.symmetric(horizontal: spec.pagePadding);

    return [
      SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: SafeShoppingStrip(onTap: () => _showProtectionInfo(context)),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.base)),
      SliverPadding(
        padding: padding,
        sliver: cartAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Column(
              children: [OrdersGroupSkeleton(), OrdersGroupSkeleton()],
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: OrdersMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Pesanan belum berhasil dimuat',
              actionLabel: 'Coba Lagi',
              onAction: () => ref.read(cartProvider.notifier).loadCart(),
            ),
          ),
          data: (cart) {
            if (cart.items.isEmpty) {
              return SliverToBoxAdapter(
                child: OrdersMessage(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Keranjangmu masih kosong',
                  message:
                      'Temukan produk Kopdes dan UMKM pilihan untuk '
                      'kebutuhanmu.',
                  actionLabel: 'Mulai Belanja',
                  onAction: () => context.go('/products'),
                ),
              );
            }

            final groups = ref.watch(cartSellerGroupsProvider);
            return SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) =>
                  CartSellerGroupCard(group: groups[index], spec: spec),
            );
          },
        ),
      ),
    ];
  }

  // ── Tab Diproses & Selesai ───────────────────────────────────

  List<Widget> _doneSlivers(WidgetRef ref) {
    final filter = ref.watch(doneFilterProvider);

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: spec.pagePadding),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: DoneFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final option = DoneFilter.values[i];
                return AppleChip(
                  label: option.label,
                  selected: option == filter,
                  onTap: () =>
                      ref.read(doneFilterProvider.notifier).state = option,
                );
              },
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.base)),
      _ordersSliver(ref, ref.watch(doneOrdersProvider), finished: true),
    ];
  }

  Widget _ordersSliver(
    WidgetRef ref,
    AsyncValue<List<Order>> async, {
    required bool finished,
  }) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: spec.pagePadding),
      sliver: async.when(
        loading: () => const SliverToBoxAdapter(
          child: Column(
            children: [OrdersGroupSkeleton(), OrdersGroupSkeleton()],
          ),
        ),
        // Kegagalan satu tab tidak menutup tab lain: keranjang punya
        // providernya sendiri dan tetap bisa dibuka.
        error: (_, __) => SliverToBoxAdapter(
          child: OrdersMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Pesanan belum berhasil dimuat',
            actionLabel: 'Coba Lagi',
            onAction: () => ref.read(orderHistoryProvider.notifier).load(),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return SliverToBoxAdapter(
              child: OrdersMessage(
                icon: finished
                    ? Icons.receipt_long_outlined
                    : Icons.local_shipping_outlined,
                title: finished
                    ? 'Belum ada riwayat pesanan selesai'
                    : 'Belum ada pesanan yang diproses',
              ),
            );
          }

          // Satu baris ekstra di kaki daftar: tombol muat-lebih, indikator,
          // atau tawaran coba lagi. Riwayat berhalaman, jadi daftar ini
          // memang belum tentu memuat seluruh pesanan.
          final page = ref.watch(orderHistoryProvider).valueOrNull;
          final showFooter =
              page != null && (page.hasMore || page.loadMoreFailed);

          return SliverList.builder(
            itemCount: orders.length + (showFooter ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= orders.length) {
                return _HistoryFooter(state: page!);
              }
              return OrderStatusCard(order: orders[index], finished: finished);
            },
          );
        },
      ),
    );
  }

  void _showProtectionInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppleRadii.group),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Belanja Aman di KMP Mitra',
                style: AppTypography.titleMedium.copyWith(fontSize: 17),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final line in const [
                'Setiap penjual di sini terdaftar: Kopdes adalah koperasi desa '
                    'resmi, dan Mitra UMKM telah diverifikasi admin Kopdes '
                    'desanya.',
                'Pembayaran QRIS masuk ke rekening Kopdes, bukan ke rekening '
                    'pribadi penjual.',
                'Pengantaran dicatat dengan koordinat kurir dan penerima, '
                    'sehingga setiap pesanan punya bukti serah terima.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          line,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.body,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kaki daftar riwayat: muat halaman berikutnya, atau tawarkan coba lagi.
///
/// Muat-lebih dipicu tombol, bukan gulir otomatis: tab ini dibuka untuk
/// mencari satu pesanan tertentu, dan menarik halaman demi halaman sendiri
/// akan menghabiskan kuota pemesan untuk baris yang tidak ia cari.
class _HistoryFooter extends ConsumerWidget {
  const _HistoryFooter({required this.state});

  final OrderHistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final failed = state.loadMoreFailed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: TextButton.icon(
          onPressed: () => ref.read(orderHistoryProvider.notifier).loadMore(),
          icon: Icon(
            failed ? Icons.refresh_rounded : Icons.expand_more_rounded,
            size: 18,
          ),
          label: Text(
            failed
                ? 'Gagal memuat, coba lagi'
                : 'Muat pesanan sebelumnya (${state.total - state.orders.length} lagi)',
          ),
          style: TextButton.styleFrom(
            foregroundColor: failed ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
