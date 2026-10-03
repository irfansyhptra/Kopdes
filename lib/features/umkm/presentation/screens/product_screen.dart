import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/product_card.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/components/empty_state_widget.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/product_controller.dart';
import '../widgets/seller_page_ui.dart';
import '../widgets/stock_live_panel.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ref.read(sellerProductQueryProvider);
      _searchController.text = query.search;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(sellerProductQueryProvider.notifier).update((state) {
        return state.copyWith(search: text, page: 1);
      });
    });
  }

  void _onCategorySelected(String categoryId) {
    ref.read(sellerProductQueryProvider.notifier).update((state) {
      final currentCategory = state.categoryId;
      // Toggle category selection
      final nextCategory = currentCategory == categoryId ? '' : categoryId;
      return state.copyWith(categoryId: nextCategory, page: 1);
    });
  }

  /// Produk yang penyesuaian stoknya sedang berjalan.
  final Set<String> _adjusting = {};

  /// Menambah atau mengurangi stok satu langkah.
  ///
  /// Lewat buku besar inventaris, bukan tulis-timpa kolom stok: tiap langkah
  /// meninggalkan catatan, dan pemantauan langsung di atas ikut
  /// menampilkannya seperti pergerakan dari kasir.
  Future<void> _adjustStock(String productId, String name, int delta) async {
    if (_adjusting.contains(productId)) return;
    setState(() => _adjusting.add(productId));

    final ok = await ref
        .read(inventoryControllerProvider.notifier)
        .adjustStock(productId, delta);

    if (!mounted) return;
    setState(() => _adjusting.remove(productId));

    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Stok "$name" gagal diperbarui'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _confirmDelete(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus Produk?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$productName"? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ref
          .read(productControllerProvider.notifier)
          .deleteProduct(productId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus produk'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(sellerProductsProvider);
    final categoriesState = ref.watch(sellerCategoriesProvider);
    final query = ref.watch(sellerProductQueryProvider);

    final productCount = productsState.valueOrNull?.length;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SellerPageChrome(
        title: 'Produk Toko',
        subtitle: productCount == null
            ? 'Kelola etalase dan ketersediaan produk'
            : '$productCount produk di etalase Anda',
        actions: [
          GlassIconButton(
            icon: Icons.add_rounded,
            label: 'Tambah produk',
            onDark: true,
            onTap: () => context.push('/umkm/products/new'),
          ),
        ],
        headerChild: SizedBox(
          height: 46,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Cari produk di toko Anda',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.muted,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(_searchController.clear);
                        ref.read(sellerProductQueryProvider.notifier).update((
                          state,
                        ) {
                          return state.copyWith(search: '', page: 1);
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.canvas,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: const BorderSide(color: Color(0x29FFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: const BorderSide(
                  color: AppColors.yellowAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Pemantauan stok pindah ke sini: halaman Stok yang terpisah
            // dilebur, karena melihat pergerakan lalu mengubah stok adalah
            // satu pekerjaan, bukan dua halaman.
            const SellerContentBoundary(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: StockLivePanel(),
            ),
            categoriesState.when(
              data: (categories) {
                if (categories.isEmpty) return const SizedBox(height: 12);
                return SellerContentBoundary(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.xs,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return AppleChip(
                          label: category.name,
                          selected: query.categoryId == category.id,
                          onTap: () => _onCategorySelected(category.id),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 56,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox(height: AppSpacing.md),
            ),
            Expanded(
              child: SellerContentBoundary(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: productsState.when(
                  loading: () => const ProductListSkeleton(),
                  error: (error, stack) => ErrorStateWidget(
                    errorMessage: error.toString(),
                    onRetry: () => ref.invalidate(sellerProductsProvider),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'Produk Kosong',
                        description: query.search.isNotEmpty
                            ? 'Tidak ada produk yang cocok dengan pencarian Anda.'
                            : 'Mulai pasarkan produk UMKM Anda dengan menambahkan produk baru!',
                        actionLabel: query.search.isNotEmpty
                            ? 'Reset Pencarian'
                            : null,
                        onAction: query.search.isNotEmpty
                            ? () {
                                _searchController.clear();
                                ref
                                    .read(sellerProductQueryProvider.notifier)
                                    .update((state) {
                                      return state.copyWith(
                                        search: '',
                                        categoryId: '',
                                        page: 1,
                                      );
                                    });
                              }
                            : null,
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.sm,
                        0,
                        112,
                      ),
                      // Satu kolom di ponsel, dua mulai tablet — dan tinggi
                      // dalam piksel, bukan rasio. Dua kolom yang dipaksa di
                      // semua lebar membuat baris kontrol (Switch 51px + dua
                      // tombol 44px = 139px perabot tetap) bertabrakan di kartu
                      // yang isinya cuma 106dp, sementara rasio 0,58 meluber
                      // 95px ke bawah di layar 320dp.
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: sellerProductCardMaxWidth,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: sellerProductCardHeight(context),
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          stockBusy: _adjusting.contains(product.id),
                          onAdjustStock: (delta) =>
                              _adjustStock(product.id, product.name, delta),
                          onEdit: () =>
                              context.push('/umkm/products/edit/${product.id}'),
                          onDelete: () =>
                              _confirmDelete(product.id, product.name),
                          onToggleActive: (val) async {
                            final success = await ref
                                .read(productControllerProvider.notifier)
                                .updateProduct(id: product.id, isActive: val);
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal mengubah status aktif produk',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          onTap: () => context.push(
                            '/umkm/products/detail/${product.id}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
