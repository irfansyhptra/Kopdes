import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/order_status_view.dart';
import '../providers/orders_page_provider.dart';

/// Warna lencana penjual. Hanya dua nilai ini yang belum ada di [AppColors],
/// jadi hanya keduanya yang didefinisikan di sini.
class SellerBadgeColors {
  static const Color kopdesSurface = Color(0xFFE7F6EC);
  static const Color kopdesText = Color(0xFF15803D);
  static const Color umkmSurface = Color(0xFFF0E8FF);
  static const Color umkmText = Color(0xFF7442C8);
}

/// Header ringkas halaman Pesanan.
///
/// Sengaja bukan AppBar merah setinggi 100dp seperti layar lama: judulnya
/// mengalir bersama konten, sehingga ruang layar dipakai untuk produk.
class OrdersHeader extends StatelessWidget {
  final int notificationCount;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  const OrdersHeader({
    super.key,
    required this.notificationCount,
    required this.onSearch,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pesanan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola belanja dan pesananmu',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderAction(
            icon: Icons.search_rounded,
            label: 'Cari produk di Marketplace',
            onTap: onSearch,
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            label: notificationCount > 0
                ? 'Notifikasi, $notificationCount belum dibaca'
                : 'Notifikasi',
            badge: notificationCount,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: label,
      child: SizedBox(
        // Target sentuh 44dp walaupun kotak yang terlihat lebih kecil.
        width: 44,
        height: 44,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppleRadii.control),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Icon(icon, size: 19, color: AppColors.ink),
              ),
              if (badge > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.canvas, width: 1.5),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented control tiga subhalaman.
///
/// Bukan [TabBar]: label "Keranjang" dan "Diproses" beserta badge-nya terpotong
/// di TabBar pada layar 320dp. Di sini setiap segmen boleh mengecil sendiri,
/// dan bila tetap tidak muat deretannya digulir mendatar.
class OrdersTabs extends ConsumerWidget {
  const OrdersTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ordersTabProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final activeCount = ref.watch(activeOrderCountProvider);

    int badgeFor(OrdersTab tab) => switch (tab) {
      OrdersTab.cart => cartCount,
      OrdersTab.active => activeCount,
      OrdersTab.done => 0,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tiga segmen berdampingan butuh ruang; di bawah ini label mulai
        // terpotong, jadi deretannya digulir.
        final fits = constraints.maxWidth >= 300;

        final segments = [
          for (final tab in OrdersTab.values)
            _TabSegment(
              tab: tab,
              badge: badgeFor(tab),
              selected: tab == active,
              expanded: fits,
              onTap: () => ref.read(ordersTabProvider.notifier).state = tab,
            ),
        ];

        if (!fits) {
          return SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: segments.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => segments[i],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppleRadii.tile),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(children: segments),
        );
      },
    );
  }
}

class _TabSegment extends StatelessWidget {
  final OrdersTab tab;
  final int badge;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _TabSegment({
    required this.tab,
    required this.badge,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  static const _icons = {
    OrdersTab.cart: Icons.shopping_bag_outlined,
    OrdersTab.active: Icons.local_shipping_outlined,
    OrdersTab.done: Icons.task_alt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.body;

    final segment = Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${tab.label}, $badge pesanan' : tab.label,
      child: ApplePressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppleRadii.control + 2),
            border: expanded
                ? null
                : Border.all(
                    color: selected ? AppColors.primary : AppColors.hairline,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icons[tab], size: 15, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonSm.copyWith(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 17),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x40FFFFFF)
                        : AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: selected ? AppColors.onPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return expanded ? Expanded(child: segment) : segment;
  }
}

/// Strip kepercayaan di atas daftar keranjang.
class SafeShoppingStrip extends StatelessWidget {
  final VoidCallback onTap;

  const SafeShoppingStrip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: 'Belanja Aman di KMP Mitra, lihat perlindungan transaksi',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppleRadii.tile - 2),
          border: Border.all(color: AppColors.primaryFaint),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_good_rounded,
                color: AppColors.primary,
                size: 15,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Belanja Aman di KMP Mitra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  Text(
                    'Transaksi Kopdes dan UMKM terlindungi',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedSoft,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pesan kosong atau gagal, dengan satu tindakan lanjutan.
class OrdersMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OrdersMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.base),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Skeleton satu grup penjual. Ukurannya mengikuti kartu sungguhan supaya
/// daftar tidak melompat saat data datang.
class OrdersGroupSkeleton extends StatelessWidget {
  const OrdersGroupSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppleRadii.tile),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 22, height: 22, borderRadius: 6),
                SizedBox(width: 10),
                ShimmerBox(width: 120, height: 13, borderRadius: 4),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                ShimmerBox(width: 66, height: 66, borderRadius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: double.infinity,
                        height: 13,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 11, borderRadius: 4),
                      SizedBox(height: 12),
                      ShimmerBox(width: 110, height: 15, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
