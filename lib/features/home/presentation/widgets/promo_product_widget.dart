import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';

class PromoProductItemData {
  final String id;
  final String name;
  final String subtitle;
  final String discountBadge;
  final double currentPrice;
  final double originalPrice;
  final String imageUrl;
  final bool isFavorite;

  const PromoProductItemData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.discountBadge,
    required this.currentPrice,
    required this.originalPrice,
    required this.imageUrl,
    this.isFavorite = false,
  });
}

/// Carousel card item promo. Kartunya solid — hanya tombol favorit di atas
/// gambar yang memakai glass, karena ia mengambang di atas media.
class PromoProductWidget extends StatefulWidget {
  final List<PromoProductItemData> products;
  final ValueChanged<PromoProductItemData> onProductTap;
  final ValueChanged<PromoProductItemData> onAddToCartTap;
  final ValueChanged<PromoProductItemData> onFavoriteToggle;
  final VoidCallback onSeeAllTap;

  const PromoProductWidget({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onAddToCartTap,
    required this.onFavoriteToggle,
    required this.onSeeAllTap,
  });

  @override
  State<PromoProductWidget> createState() => _PromoProductWidgetState();
}

class _PromoProductWidgetState extends State<PromoProductWidget> {
  late Set<String> _favoriteIds = widget.products
      .where((p) => p.isFavorite)
      .map((p) => p.id)
      .toSet();

  void _toggleFav(String id) {
    setState(() {
      _favoriteIds.contains(id)
          ? _favoriteIds.remove(id)
          : _favoriteIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: 'Promo Terbaik',
          subtitle: 'Harga khusus anggota, terbatas minggu ini',
          actionLabel: 'Semua',
          onAction: widget.onSeeAllTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 238,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: widget.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final p = widget.products[index];
              return SizedBox(
                width: 148,
                child: AppleProductTile(
                  imageUrl: p.imageUrl,
                  title: p.name,
                  subtitle: p.subtitle,
                  price: formatRupiah(p.currentPrice),
                  originalPrice: formatRupiah(p.originalPrice),
                  badge: p.discountBadge,
                  imageHeight: 112,
                  imageFit: BoxFit.contain,
                  isFavorite: _favoriteIds.contains(p.id),
                  onFavoriteTap: () {
                    _toggleFav(p.id);
                    widget.onFavoriteToggle(p);
                  },
                  onTap: () => widget.onProductTap(p),
                  onAdd: () => widget.onAddToCartTap(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
