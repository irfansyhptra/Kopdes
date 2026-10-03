import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../koperasi/presentation/providers/koperasi_store_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_action_bar.dart';
import '../../../order/data/review_repository.dart';
import '../../../marketplace/presentation/widgets/product_carousel.dart';
import '../../../order/presentation/cart_feedback.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../widgets/product_detail_sections.dart';
import '../widgets/purchase_bottom_sheet.dart';

/// Halaman detail produk.
///
/// Tanpa bilah navigasi bawah: tempatnya dipakai bilah aksi, dan keluar dari
/// halaman ini lewat panah di kiri atas. Menampilkan keduanya sekaligus
/// membuat dua baris tombol bertumpuk di kaki layar pada ponsel kecil.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _pageController = PageController();
  int _imageIndex = 0;
  bool _openingChat = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openSellerChat(Product product) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .startProductSellerConversation(product.id);
      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
      if (!mounted) return;
      context.push(
        ChatChannel.marketplace.detailPath(conversation.id),
        extra: ChatDetailArguments(
          title: product.store?.name ?? product.name,
          channel: ChatChannel.marketplace,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  /// Jarak toko dari posisi pengguna.
  ///
  /// Dihitung di sini, bukan di server: endpoint detail produk tidak tahu di
  /// mana pembacanya berada, dan mengirim koordinat pengguna hanya untuk satu
  /// angka berarti membocorkan lokasinya ke setiap permintaan produk.
  String? _distanceLabel(Product product) {
    final store = product.store;
    final me = ref.watch(locationProvider.select((s) => s.location));
    if (store?.latitude == null || store?.longitude == null || me == null) {
      return null;
    }

    final meters = _haversineMeters(
      me.latitude,
      me.longitude,
      store!.latitude!,
      store.longitude!,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    double toRad(double deg) => deg * math.pi / 180;

    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: async.when(
        loading: () => const Center(
          child: AppleActivityIndicator(size: 36, color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () =>
              ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) => _Body(
          product: product,
          pageController: _pageController,
          imageIndex: _imageIndex,
          onImageChanged: (i) => setState(() => _imageIndex = i),
          onThumbTap: (i) {
            setState(() => _imageIndex = i);
            _pageController.animateToPage(
              i,
              duration: AppAnimation.normal,
              curve: Curves.easeOut,
            );
          },
          distanceLabel: _distanceLabel(product),
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (product) => ProductActionBar(
          price: product.effectivePrice,
          outOfStock: product.stock <= 0,
          chatBusy: _openingChat,
          onChat: () => _openSellerChat(product),
          onAddToCart: () => showPurchaseBottomSheet(context, product: product),
          onBuyNow: () => showPurchaseBottomSheet(
            context,
            product: product,
            isDirectCheckout: true,
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Product product;
  final PageController pageController;
  final int imageIndex;
  final ValueChanged<int> onImageChanged;
  final ValueChanged<int> onThumbTap;
  final String? distanceLabel;

  const _Body({
    required this.product,
    required this.pageController,
    required this.imageIndex,
    required this.onImageChanged,
    required this.onThumbTap,
    required this.distanceLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = product.store;

    return CustomScrollView(
      slivers: [
        _Banner(
          product: product,
          controller: pageController,
          index: imageIndex,
          onChanged: onImageChanged,
        ),
        _Block(child: ProductHeadline(product: product)),
        _Block(child: _Description(product: product)),
        if (product.images.length > 1)
          _Block(
            child: ProductPhotoStrip(
              images: product.images,
              activeIndex: imageIndex,
              onSelect: onThumbTap,
            ),
          ),
        const _Block(child: ShippingOptions()),

        // Urutannya: toko dulu, lalu penilaian produknya, baru barang lain
        // di toko yang sama. Penilaian dulu ditaruh di atas kartu toko,
        // sehingga pembaca melompat dari ulasan ke identitas penjual lalu
        // kembali lagi ke barang — tiga langkah untuk satu alur pikiran.
        if (store != null)
          _Block(
            child: StoreCard(
              store: store,
              ratingAverage: product.ratingAverage,
              ratingCount: product.ratingCount,
              distanceLabel: distanceLabel,
            ),
          ),
        _Block(
          child: ProductReviewSection(
            target: ReviewTarget.kopdes(product.id),
            ratingAverage: product.ratingAverage,
            ratingCount: product.ratingCount,
          ),
        ),
        if (store != null)
          _StoreCarousel(
            title: 'Produk Lainnya di Toko',
            store: (id: store.id, isUmkm: false),
            excludeId: product.id,
          ),
        _StoreCarousel(
          title: 'Rekomendasi Produk',
          store: (id: '', isUmkm: false),
          excludeId: product.id,
          recommendation: true,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );
  }
}

/// Jarak antar-bagian dipegang satu widget supaya iramanya tidak dihitung
/// ulang — dan salah — di tiap bagian.
class _Block extends StatelessWidget {
  final Widget child;

  const _Block({required this.child});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.base,
        0,
      ),
      child: child,
    ),
  );
}

class _Banner extends StatelessWidget {
  final Product product;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;

  const _Banner({
    required this.product,
    required this.controller,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.images;

    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).width,
      pinned: true,
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      // Panah kembali di atas foto terang perlu permukaannya sendiri.
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: ApplePressable(
          onTap: () => Navigator.of(context).maybePop(),
          semanticLabel: 'Kembali',
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: AppElevation.subtle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceSoft,
              child: images.isEmpty
                  ? const ProductImageLoader(
                      imageUrl: '',
                      placeholderIconSize: 48,
                    )
                  : PageView.builder(
                      controller: controller,
                      onPageChanged: onChanged,
                      itemCount: images.length,
                      itemBuilder: (context, i) => ProductImageLoader(
                        imageUrl: images[i].url,
                        placeholderIconSize: 48,
                      ),
                    ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: AppSpacing.base,
                right: AppSpacing.base,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x8C1D1D1F),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${index + 1}/${images.length}',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  final Product product;

  const _Description({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppleSectionHeader(
          title: 'Deskripsi Produk',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppleCard(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _InfoChip(label: 'Satuan', value: product.unit),
                  if (product.category != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _InfoChip(label: 'Kategori', value: product.category!.name),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                product.description.trim().isEmpty
                    ? 'Penjual belum menuliskan deskripsi produk ini.'
                    : product.description,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  height: 1.55,
                  color: product.description.trim().isEmpty
                      ? AppColors.mutedSoft
                      : AppColors.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carousel rapat untuk "produk lain dari toko ini" dan "rekomendasi".
///
/// Produk yang sedang dibuka dibuang dari daftarnya — menampilkannya lagi di
/// bawah halamannya sendiri hanya membuang satu kartu.
class _StoreCarousel extends ConsumerWidget {
  final String title;
  final StoreRef store;
  final String excludeId;
  final bool recommendation;

  const _StoreCarousel({
    required this.title,
    required this.store,
    required this.excludeId,
    this.recommendation = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rekomendasi memakai katalog penuh; "produk lain" dikunci pada tokonya.
    final ref0 = recommendation ? (id: '', isUmkm: false) : store;
    final async = ref.watch(storeProductsProvider(ref0));

    return async.maybeWhen(
      data: (page) {
        final items = page.items
            .where((p) => p.id != excludeId)
            .take(10)
            .toList(growable: false);
        if (items.isEmpty) return const SliverToBoxAdapter();

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppleSectionHeader(title: title),
                const SizedBox(height: AppSpacing.sm),
                // Kartu dan ukuran yang sama dengan etalase Marketplace —
                // satu produk tidak boleh terlihat berbeda hanya karena
                // halaman yang menggambarnya berbeda.
                ProductCarousel(
                  products: items,
                  onTap: (p) => context.push(
                    p.isUmkm
                        ? '/mitra/products/${p.id}'
                        : '/products/detail/${p.id}',
                  ),
                  onAddToCart: (p) => addToCartWithFeedback(
                    context,
                    productName: p.name,
                    add: () => ref
                        .read(cartProvider.notifier)
                        .addToCart(
                          productId: p.isUmkm ? null : p.id,
                          umkmProductId: p.isUmkm ? p.id : null,
                          quantity: 1,
                          productName: p.name,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SliverToBoxAdapter(),
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
