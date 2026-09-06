import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'apple_ui.dart';
import 'shimmer_loading.dart';

// ─────────────────────────────────────────────────────────
// Skeleton Loaders — placeholder yang menyerupai widget aslinya
//
// Tiap komposit membungkus dirinya dengan satu [ShimmerGroup], jadi seluruh
// kotak di dalamnya berbagi SATU AnimationController. Sebelumnya tiap
// ShimmerBox punya controller sendiri: satu grid 4 kartu = 16 Ticker aktif.
// ─────────────────────────────────────────────────────────

/// Rangka kartu produk grid.
///
/// Ukurannya dicocokkan dengan [AppleProductTile] — gambar 132px, radius 20,
/// hairline — supaya tata letak tidak bergeser saat data asli menggantikannya.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(child: _body());
  }

  /// Dipakai langsung oleh [ProductGridSkeleton] yang sudah menyediakan grup,
  /// supaya grid tidak membuat satu grup per sel.
  static Widget bare() => _body();

  static Widget _body() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.hairline,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppleRadii.card),
            ),
            child: ShimmerBox(
              width: double.infinity,
              height: 132,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 13, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 70, height: 10, borderRadius: 4),
                SizedBox(height: 12),
                ShimmerBox(width: 90, height: 15, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangka satu baris produk di dalam [AppleListGroup].
class ProductRowSkeleton extends StatelessWidget {
  const ProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ShimmerBox(width: 60, height: 60, borderRadius: 10),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 150, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 100, height: 11, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangka daftar produk bergaya inset grouped list.
///
/// Namanya dibedakan dari `ProductListSkeleton` di `loading_widget.dart`;
/// keduanya sempat bernama sama padahal bentuknya berbeda.
class GroupedProductListSkeleton extends StatelessWidget {
  final int itemCount;

  const GroupedProductListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: AppleListGroup(
        children: List.generate(itemCount, (_) => const ProductRowSkeleton()),
      ),
    );
  }
}

/// Rangka grid produk 2 kolom.
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.55,
        ),
        itemCount: itemCount,
        itemBuilder: (context, _) => ProductCardSkeleton.bare(),
      ),
    );
  }
}

/// Rangka area promo/banner beranda.
class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerGroup(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: ShimmerBox(
          width: double.infinity,
          height: 160,
          borderRadius: 24,
        ),
      ),
    );
  }
}

/// Rangka satu kartu notifikasi.
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
                SizedBox(height: 4),
                ShimmerBox(width: 120, height: 10, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 8, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangka daftar notifikasi.
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;

  const NotificationListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const NotificationCardSkeleton(),
        ),
      ),
    );
  }
}

/// Rangka baris kategori beranda.
class HomeCategorySkeleton extends StatelessWidget {
  const HomeCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => const Column(
            children: [
              ShimmerBox(width: 52, height: 52, borderRadius: 16),
              SizedBox(height: 6),
              ShimmerBox(width: 40, height: 8, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
