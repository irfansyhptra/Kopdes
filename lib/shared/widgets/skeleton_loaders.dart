import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

// ─────────────────────────────────────────────────────────
// Skeleton Loaders — Composed loading placeholders
// matching actual widget layouts
// ─────────────────────────────────────────────────────────

/// Skeleton for a single product card in a grid
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            child: ShimmerBox(width: double.infinity, height: 140, borderRadius: 0),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                const ShimmerBox(width: 60, height: 10, borderRadius: 4),
                const SizedBox(height: 8),
                // Product title
                const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 4),
                const ShimmerBox(width: 100, height: 12, borderRadius: 4),
                const SizedBox(height: 10),
                // Price
                const ShimmerBox(width: 80, height: 14, borderRadius: 6),
                const SizedBox(height: 8),
                // Button
                ShimmerBox(
                  width: double.infinity,
                  height: 32,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a 2-column product grid
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
      itemBuilder: (context, _) => const ProductCardSkeleton(),
    );
  }
}

/// Skeleton for the home screen promo/banner area
class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ShimmerBox(
        width: double.infinity,
        height: 160,
        borderRadius: 24,
      ),
    );
  }
}

/// Skeleton for a single notification card
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle avatar
          const ShimmerBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 160, height: 12, borderRadius: 4),
                const SizedBox(height: 6),
                const ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
                const SizedBox(height: 4),
                const ShimmerBox(width: 120, height: 10, borderRadius: 4),
                const SizedBox(height: 8),
                const ShimmerBox(width: 80, height: 8, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a list of notification items
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;

  const NotificationListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const NotificationCardSkeleton(),
      ),
    );
  }
}

/// Skeleton for the home category row
class HomeCategorySkeleton extends StatelessWidget {
  const HomeCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) {
          return Column(
            children: const [
              ShimmerBox(width: 52, height: 52, borderRadius: 16),
              SizedBox(height: 6),
              ShimmerBox(width: 40, height: 8, borderRadius: 4),
            ],
          );
        },
      ),
    );
  }
}
