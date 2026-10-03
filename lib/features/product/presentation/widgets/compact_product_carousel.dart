import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../marketplace/domain/marketplace.dart';

/// Carousel produk rapat — tiga kartu muat dalam satu layar.
///
/// Dipakai di halaman detail sebagai pelengkap: kartu selebar etalase akan
/// menyaingi barang yang sedang dilihat, dan pembaca kehilangan konteks
/// halaman yang sedang dibukanya.
class CompactProductCarousel extends StatelessWidget {
  final List<MarketplaceProduct> products;

  const CompactProductCarousel({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = compactCarouselCardWidth(constraints.maxWidth);
        // Foto 1:1 + nama dua baris + harga. Rasionya lebih tinggi daripada
        // kartu etalase karena kartunya jauh lebih sempit: nama yang sama
        // membungkus lebih banyak baris.
        final height = width / 0.52;

        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: width,
                child: AppleProductTile(
                  imageUrl: product.imageUrl ?? '',
                  imageHeight: width,
                  title: product.name,
                  subtitle: product.sellerName,
                  price: formatRupiah(product.effectivePrice),
                  onTap: () => context.push(
                    product.isUmkm
                        ? '/mitra/products/${product.id}'
                        : '/products/detail/${product.id}',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
