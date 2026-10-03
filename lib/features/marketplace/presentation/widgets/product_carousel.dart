import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/marketplace.dart';
import '../../../../shared/widgets/apple_ui.dart';
import 'marketplace_product_card.dart';

/// Carousel produk mendatar.
///
/// Memakai [MarketplaceProductCard] yang sama dengan grid — bukan salinan
/// kedua. Lebarnya dari [marketplaceCardWidth] dan tingginya dari
/// [productCardAspectRatio], keduanya aturan yang sama dengan grid, jadi
/// kartu yang sama tidak punya dua ukuran tergantung siapa menggambarnya.
///
/// `ListView.builder` tanpa `shrinkWrap`: daftarnya bisa panjang, dan
/// shrink-wrap memaksa seluruh isinya dibangun sekaligus.
class ProductCarousel extends StatelessWidget {
  final List<MarketplaceProduct> products;
  final ValueChanged<MarketplaceProduct> onTap;
  final ValueChanged<MarketplaceProduct> onAddToCart;

  const ProductCarousel({
    super.key,
    required this.products,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    // `LayoutBuilder`, bukan `MediaQuery.sizeOf`: lebarnya diambil dari ruang
    // yang benar-benar diberikan kepada daftar ini, sehingga carousel di dalam
    // panel sempit pada tablet ikut menyesuaikan.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar yang sama dengan grid Marketplace, bukan rumus carousel
        // tersendiri: kartu yang sama tidak boleh punya dua ukuran.
        final width = marketplaceCardWidth(constraints.maxWidth);
        // Tinggi dihitung dari lebar dan rasio yang sama dengan grid, bukan
        // angka tetap: daftar mendatar butuh tinggi terbatas, dan menebaknya
        // membuat teks terpotong begitu skala teks sistem dinaikkan.
        final height = width / productCardAspectRatio(context);

        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: width,
                child: MarketplaceProductCard(
                  product: product,
                  onTap: () => onTap(product),
                  onAddToCart: () => onAddToCart(product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
