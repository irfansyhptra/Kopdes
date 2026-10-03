import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../order/presentation/cart_feedback.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../domain/discovery.dart';
import '../providers/discovery_provider.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

/// Detail produk Mitra UMKM untuk pelanggan.
///
/// Terpisah dari `ProductDetailScreen` milik produk Kopdes: keduanya berasal
/// dari tabel berbeda, memakai endpoint berbeda, dan parameter keranjang yang
/// berbeda pula (`umkmProductId`, bukan `productId`). Menyatukannya berarti
/// setiap bagian harus bercabang — dua layar kecil lebih jujur.
class UmkmProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const UmkmProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<UmkmProductDetailScreen> createState() =>
      _UmkmProductDetailScreenState();
}

class _UmkmProductDetailScreenState
    extends ConsumerState<UmkmProductDetailScreen> {
  bool _adding = false;
  bool _openingChat = false;

  Future<void> _openSellerChat(UmkmProductDetail product) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .startUmkmProductSellerConversation(product.id);
      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
      if (!mounted) return;
      context.push(
        ChatChannel.marketplace.detailPath(conversation.id),
        extra: ChatDetailArguments(
          title: product.sellerName,
          channel: ChatChannel.marketplace,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penjual belum dapat dihubungi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _addToCart(UmkmProductDetail product) async {
    if (_adding) return;
    setState(() => _adding = true);

    // Produk mitra dikirim sebagai umkmProductId; mengirimkannya sebagai
    // productId membuat backend mencarinya di tabel Product dan menjawab 404.
    await addToCartWithFeedback(
      context,
      productName: product.name,
      add: () => ref
          .read(cartProvider.notifier)
          .addToCart(
            umkmProductId: product.id,
            quantity: 1,
            productName: product.name,
          ),
    );

    if (!mounted) return;
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(umkmProductDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () =>
              ref.invalidate(umkmProductDetailProvider(widget.productId)),
        ),
        data: (product) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                background: ProductImageLoader(
                  imageUrl: product.primaryImageUrl ?? '',
                  placeholderIconSize: 48,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppleBadge(label: 'Produk Lokal'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      product.name,
                      style: AppTypography.titleLarge.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatRupiah(product.price),
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (product.ratingCount > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.ratingAverage!.toStringAsFixed(1).replaceAll('.', ',')}'
                            ' (${product.ratingCount})',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Text(
                          product.isOutOfStock
                              ? 'Stok habis'
                              : 'Stok ${product.stock}',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 12,
                            color: product.isOutOfStock
                                ? AppColors.errorText
                                : AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),

                    if (product.description.isNotEmpty) ...[
                      Text(
                        product.description,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Penjualnya bisa dibuka — inilah yang tidak bisa
                    // dilakukan halaman produk Kopdes.
                    AppleCard(
                      onTap: product.umkmId.isEmpty
                          ? null
                          : () => context.push('/mitra/${product.umkmId}'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      clip: false,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (product.sellerAddress.isNotEmpty)
                                  Text(
                                    product.sellerAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.captionSmall,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.mutedSoft,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (product) => SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  onPressed: _openingChat
                      ? null
                      : () => _openSellerChat(product),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: _openingChat
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    // Stok habis mematikan tombol, bukan sekadar mengubah warnanya.
                    onPressed: product.isOutOfStock || _adding
                        ? null
                        : () => _addToCart(product),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      product.isOutOfStock
                          ? 'Stok Habis'
                          : _adding
                          ? 'Menambahkan...'
                          : 'Tambah ke Keranjang',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Produk belum berhasil dimuat.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
