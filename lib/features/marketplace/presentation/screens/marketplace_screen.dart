import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../discovery/presentation/widgets/discovery_sections.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../domain/marketplace.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/marketplace_filter_sheet.dart';
import '../widgets/marketplace_filters.dart';
import '../widgets/marketplace_product_card.dart';

/// Halaman Marketplace.
///
/// Menggantikan `ProductCatalogScreen` lama yang menampilkan `HomeHeaderWidget`
/// dan `MemberCardWidget` — itulah sebabnya halaman ini dulu terlihat seperti
/// beranda. Tidak ada header profil maupun sapaan di sini: konten dimulai
/// langsung setelah safe area.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Ruang bagi bilah navigasi mengambang agar kartu terakhir tidak tertutup.
  static const double _navBarClearance = 96;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Kolom pencarian diisi dari state agar pilihan pengguna bertahan saat
    // kembali dari halaman detail produk.
    _searchController.text = ref.read(marketplaceFilterProvider).search;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      ref.read(marketplaceProductsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // Tanpa debounce, setiap huruf mengirim satu permintaan.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(marketplaceFilterProvider.notifier)
          .update((f) => f.copyWith(search: value));
    });
  }

  Future<void> _onRefresh() =>
      ref.read(marketplaceProductsProvider.notifier).load(forceRefresh: true);

  /// "Lihat Semua" dan "Atur Ulang Filter" bermuara ke hal yang sama:
  /// mengosongkan setiap filter sehingga katalog penuh yang tampil. Kolom
  /// pencarian ikut dikosongkan — membiarkannya terisi sementara hasilnya
  /// sudah tidak tersaring akan menyesatkan.
  void _showAll() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(showFavoritesProvider.notifier).state = false;
    ref.read(marketplaceFilterProvider.notifier).state =
        const MarketplaceFilter();
  }

  Future<void> _addToCart(MarketplaceProduct product) async {
    final adding = ref.read(addingToCartProvider);
    if (adding.contains(product.id)) return;

    ref.read(addingToCartProvider.notifier).state = {...adding, product.id};

    // Produk mitra memakai umkmProductId; mengirimnya sebagai productId
    // membuat backend mencarinya di tabel Product dan menjawab 404.
    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(
          productId: product.isUmkm ? null : product.id,
          umkmProductId: product.isUmkm ? product.id : null,
          quantity: 1,
        );

    if (!mounted) return;
    ref.read(addingToCartProvider.notifier).state = {
      ...ref.read(addingToCartProvider),
    }..remove(product.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${product.name} ditambahkan ke keranjang'
                : 'Gagal menambahkan ke keranjang',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openProduct(MarketplaceProduct product) {
    context.push(
      product.isUmkm
          ? '/umkm/products/${product.id}'
          : '/products/detail/${product.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(marketplaceFilterProvider);
    final foodCategories = ref.watch(foodCategoriesProvider);
    final retailCategories = ref.watch(retailCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.canvas,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Pada tablet, konten dibatasi lebarnya dan dipusatkan supaya
              // kartu tidak melar tak wajar.
              final maxWidth = constraints.maxWidth > 1024
                  ? 1100.0
                  : constraints.maxWidth;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.md),
                      ),

                      // 1 & 2. Iklan utama + indikator carousel. Banner punya
                      // state sendiri; kegagalannya tidak menghentikan produk.
                      const SliverToBoxAdapter(child: BannerSection()),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.base),
                      ),

                      // 3. Pencarian & filter lanjutan.
                      SliverToBoxAdapter(
                        child: _SearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            _debounce?.cancel();
                            ref
                                .read(marketplaceFilterProvider.notifier)
                                .update((f) => f.copyWith(search: ''));
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),

                      // 4. Filter Makanan.
                      SliverToBoxAdapter(
                        child: CategoryFilterRow(
                          title: 'Filter Makanan',
                          icon: Icons.restaurant_rounded,
                          categories: foodCategories,
                          selectedId: filter.foodCategoryId,
                          onSelected: (id) => ref
                              .read(marketplaceFilterProvider.notifier)
                              .update(
                                (f) => f.copyWith(
                                  foodCategoryId: id,
                                  clearFood: id == null,
                                  clearRetail: true,
                                ),
                              ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),

                      // 5. Filter Barang Ritel.
                      SliverToBoxAdapter(
                        child: CategoryFilterRow(
                          title: 'Filter Barang Ritel',
                          icon: Icons.shopping_basket_rounded,
                          categories: retailCategories,
                          selectedId: filter.retailCategoryId,
                          onSelected: (id) => ref
                              .read(marketplaceFilterProvider.notifier)
                              .update(
                                (f) => f.copyWith(
                                  retailCategoryId: id,
                                  clearRetail: id == null,
                                  clearFood: true,
                                ),
                              ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),

                      // 6 & 7. Sumber belanja + lokasi pengguna.
                      const SliverToBoxAdapter(child: ShoppingSourceSelector()),
                      const SliverToBoxAdapter(child: MarketplaceLocationBar()),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),

                      // 8. Rekomendasi Untukmu — atau daftar favorit.
                      SliverToBoxAdapter(
                        child: Consumer(
                          builder: (context, ref, _) =>
                              MarketplaceSectionHeader(
                                title: ref.watch(showFavoritesProvider)
                                    ? 'Favorit Saya'
                                    : 'Rekomendasi Untukmu',
                                actionLabel: 'Lihat Semua',
                                onAction: _showAll,
                              ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.md),
                      ),

                      _ProductGrid(
                        onOpen: _openProduct,
                        onAddToCart: _addToCart,
                        onResetFilter: _showAll,
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height:
                              _navBarClearance +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyMedium.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari produk kebutuhanmu...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                // Tombol hapus hanya muncul saat ada teks.
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Hapus pencarian',
                          onPressed: onClear,
                        ),
                ),
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const _FavoritesButton(),
          const SizedBox(width: AppSpacing.md),
          const _FilterButton(),
        ],
      ),
    );
  }
}

/// Beralih antara hasil pencarian dan daftar favorit.
class _FavoritesButton extends ConsumerWidget {
  const _FavoritesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showing = ref.watch(showFavoritesProvider);
    final count = ref.watch(favoriteProductsProvider.select((f) => f.length));

    return ApplePressable(
      onTap: () => ref.read(showFavoritesProvider.notifier).state = !showing,
      pressedScale: 0.94,
      semanticLabel: showing
          ? 'Kembali ke semua produk'
          : 'Lihat $count produk favorit',
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: showing ? AppColors.primary : AppColors.canvas,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: showing ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Icon(
          showing ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: showing ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilter = ref.watch(
      marketplaceFilterProvider.select((f) => f.hasActiveFilter),
    );

    return ApplePressable(
      onTap: () => showMarketplaceFilterSheet(context, ref),
      pressedScale: 0.94,
      semanticLabel: hasFilter ? 'Filter, sedang aktif' : 'Filter produk',
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: hasFilter ? AppColors.primary : AppColors.hairline,
            width: hasFilter ? 1.5 : 1,
          ),
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Grid produk responsif.
///
/// Jumlah kolom dihitung dari lebar yang tersedia, bukan dari jenis perangkat,
/// memakai [SliverGridDelegateWithMaxCrossAxisExtent].
class _ProductGrid extends ConsumerWidget {
  final ValueChanged<MarketplaceProduct> onOpen;
  final ValueChanged<MarketplaceProduct> onAddToCart;

  /// Dipegang layar, bukan grid: mengosongkan filter juga harus mengosongkan
  /// kolom pencarian, dan controller-nya milik layar.
  final VoidCallback onResetFilter;

  const _ProductGrid({
    required this.onOpen,
    required this.onAddToCart,
    required this.onResetFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(showFavoritesProvider)) return _favorites(context, ref);

    final async = ref.watch(marketplaceProductsProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      sliver: async.when(
        loading: () => SliverToBoxAdapter(
          child: ShimmerGroup(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: _delegate(context),
              itemCount: 4,
              itemBuilder: (_, __) => const _SkeletonCard(),
            ),
          ),
        ),
        error: (_, __) => SliverToBoxAdapter(
          child: _Message(
            title: 'Produk belum berhasil dimuat',
            actionLabel: 'Coba Lagi',
            onAction: () => ref
                .read(marketplaceProductsProvider.notifier)
                .load(forceRefresh: true),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return SliverToBoxAdapter(
              child: _Message(
                title: 'Produk belum ditemukan',
                message: 'Coba ubah kata pencarian atau filter yang digunakan.',
                actionLabel: 'Atur Ulang Filter',
                onAction: onResetFilter,
              ),
            );
          }

          return SliverMainAxisGroup(
            slivers: [
              SliverGrid.builder(
                gridDelegate: _delegate(context),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final product = state.items[index];
                  return MarketplaceProductCard(
                    product: product,
                    onTap: () => onOpen(product),
                    onAddToCart: () => onAddToCart(product),
                  );
                },
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              // Gagal memuat halaman berikutnya tidak menghapus produk yang
              // sudah tampil — hanya menawarkan mencoba lagi.
              if (state.loadMoreFailed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.base,
                    ),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(marketplaceProductsProvider.notifier)
                            .loadMore(),
                        child: const Text('Muat Lagi'),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Favorit tersimpan lokal, jadi tidak ada permintaan jaringan maupun
  /// paginasi di sini — seluruh daftarnya memang sudah ada di perangkat.
  Widget _favorites(BuildContext context, WidgetRef ref) {
    final items = ref.watch(favoriteProductsProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      sliver: items.isEmpty
          ? SliverToBoxAdapter(
              child: _Message(
                title: 'Belum ada produk favorit',
                message:
                    'Tekan ikon hati pada produk untuk menyimpannya di sini.',
                actionLabel: 'Lihat Semua Produk',
                onAction: onResetFilter,
              ),
            )
          : SliverGrid.builder(
              gridDelegate: _delegate(context),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                return MarketplaceProductCard(
                  product: product,
                  onTap: () => onOpen(product),
                  onAddToCart: () => onAddToCart(product),
                );
              },
            ),
    );
  }

  /// Rasio disesuaikan dengan skala teks: pada teks besar kartu perlu lebih
  /// tinggi, kalau tidak isinya meluber.
  SliverGridDelegate _delegate(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: (0.66 / textScale.clamp(1.0, 1.8)).clamp(0.34, 0.66),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
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
                ShimmerBox(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 10),
                ShimmerBox(width: 100, height: 15, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 34,
            color: AppColors.mutedSoft,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(fontSize: 15),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
