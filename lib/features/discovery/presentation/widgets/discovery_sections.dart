import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../home/presentation/widgets/compact_promo_banner.dart';
import '../../domain/discovery.dart';
import '../providers/discovery_provider.dart';
import 'discovery_product_card.dart';

/// Iklan utama dari API.
///
/// Isi banner datang dari `GET /banners` lewat [bannersProvider]. Daftar
/// [fallbackItems] hanya dipakai saat endpoint itu belum menjawab, gagal, atau
/// belum diisi admin — Marketplace tidak boleh kehilangan iklan utamanya hanya
/// karena satu endpoint bermasalah, tetapi isinya juga tidak boleh permanen di
/// dalam widget: begitu admin memasang banner, banner itulah yang tampil.
class BannerSection extends ConsumerWidget {
  const BannerSection({super.key});

  /// Iklan bawaan Marketplace, dipakai hanya sebagai cadangan.
  static const List<PromoBannerItem> fallbackItems = [
    PromoBannerItem(
      badge: 'PROMO HARI INI',
      title: 'Belanja Hemat di',
      highlight: 'KMP Mitra',
      description: 'Produk Kopdes dan UMKM pilihan untuk kebutuhan keluarga.',
      cta: 'Belanja Sekarang',
      icon: Icons.shopping_basket_rounded,
    ),
  ];

  /// Tinggi banner mengikuti lebar dan skala teks, bukan angka tetap dari
  /// screenshot: pada 320dp banner tetap ramping, pada tablet ia melebar tanpa
  /// menjadi terlalu jangkung, dan pada teks besar ia tumbuh supaya isinya
  /// tetap muat.
  static double _height(BuildContext context, double width) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final base = (width * 0.40).clamp(126.0, 152.0);
    return base * textScale.clamp(1.0, 1.7);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bannersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _height(context, constraints.maxWidth);

        Widget banner(
          List<PromoBannerItem> items,
          ValueChanged<PromoBannerItem> onTap,
        ) {
          return CompactPromoBanner(
            items: items,
            height: height,
            autoPlay: true,
            onCtaTap: onTap,
          );
        }

        return async.when(
          loading: () => _BannerSkeleton(height: height),
          error: (_, __) =>
              banner(fallbackItems, (_) => context.go('/products')),
          data: (banners) {
            if (banners.isEmpty) {
              return banner(fallbackItems, (_) => context.go('/products'));
            }
            return banner(banners.map(_toItem).toList(growable: false), (item) {
              final route = _routeFor(banners, item);
              if (route != null) context.go(route);
            });
          },
        );
      },
    );
  }

  PromoBannerItem _toItem(PromoBanner b) => PromoBannerItem(
    badge: b.badge ?? 'PROMO',
    title: b.title,
    highlight: b.highlight ?? '',
    description: b.description ?? '',
    cta: b.ctaLabel ?? 'Lihat',
    icon: Icons.shopping_basket_rounded,
    imageUrl: b.imageUrl,
  );

  /// Mencocokkan item yang ditekan kembali ke banner asalnya untuk mengambil
  /// rute tujuannya.
  String? _routeFor(List<PromoBanner> banners, PromoBannerItem item) {
    for (final b in banners) {
      if (b.title == item.title) return b.ctaRoute;
    }
    return null;
  }
}

/// Skeleton sebesar banner sungguhan, supaya tata letak tidak melompat saat
/// iklan datang.
class _BannerSkeleton extends StatelessWidget {
  final double height;

  const _BannerSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: ShimmerBox(
          width: double.infinity,
          height: height,
          borderRadius: AppleRadii.group,
        ),
      ),
    );
  }
}

/// Section "Produk UMKM Pilihan".
class FeaturedUmkmSection extends ConsumerWidget {
  final ValueChanged<DiscoveryProduct>? onAddToCart;

  const FeaturedUmkmSection({super.key, this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProductSection(
      title: 'Produk UMKM Pilihan',
      onSeeAll: () => context.push('/mitra'),
      async: ref.watch(featuredUmkmProductsProvider),
      emptyMessage: 'Belum ada produk UMKM pilihan.',
      onRetry: () => ref.invalidate(featuredUmkmProductsProvider),
      onAddToCart: onAddToCart,
    );
  }
}

/// Section "Produk Terlaris".
class BestSellersSection extends ConsumerWidget {
  final ValueChanged<DiscoveryProduct>? onAddToCart;

  const BestSellersSection({super.key, this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProductSection(
      title: 'Produk Terlaris',
      onSeeAll: () => context.go('/products'),
      async: ref.watch(bestSellersProvider),
      emptyMessage:
          'Belum ada data penjualan.\n'
          'Produk terlaris muncul setelah ada transaksi.',
      onRetry: () => ref.invalidate(bestSellersProvider),
      showRank: true,
      onAddToCart: onAddToCart,
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  final AsyncValue<List<DiscoveryProduct>> async;
  final String emptyMessage;
  final VoidCallback onRetry;
  final bool showRank;
  final ValueChanged<DiscoveryProduct>? onAddToCart;

  const _ProductSection({
    required this.title,
    required this.onSeeAll,
    required this.async,
    required this.emptyMessage,
    required this.onRetry,
    this.showRank = false,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: title,
          actionLabel: 'Lihat Semua',
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const _ProductSkeleton(),
          error: (_, __) => _Message(
            message: 'Data belum berhasil dimuat.',
            actionLabel: 'Coba Lagi',
            onAction: onRetry,
          ),
          data: (products) {
            if (products.isEmpty) return _Message(message: emptyMessage);

            return SizedBox(
              height: 238,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return DiscoveryProductCard(
                    product: product,
                    showRank: showRank,
                    onTap: () => context.push('/products/detail/${product.id}'),
                    onAdd: onAddToCart == null
                        ? null
                        : () => onAddToCart!(product),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: SizedBox(
        height: 238,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => Container(
            width: 148,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.card),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 104,
                  borderRadius: 0,
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: double.infinity,
                        height: 13,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: 70, height: 10, borderRadius: 4),
                      SizedBox(height: 12),
                      ShimmerBox(width: 90, height: 15, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
