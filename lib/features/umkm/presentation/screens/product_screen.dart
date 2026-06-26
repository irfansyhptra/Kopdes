import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/product_card.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/components/empty_state_widget.dart';
import '../controllers/product_controller.dart';

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

  Future<void> _confirmDelete(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus Produk?'),
          content: Text('Apakah Anda yakin ingin menghapus "$productName"? Tindakan ini tidak dapat dibatalkan.'),
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/umkm/products/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(sellerProductQueryProvider.notifier).update((state) {
                            return state.copyWith(search: '', page: 1);
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Categories Filter Row
          categoriesState.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = query.categoryId == cat.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (_) => _onCategorySelected(cat.id),
                        selectedColor: AppColors.primaryTint,
                        checkmarkColor: AppColors.primary,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.ink,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surfaceSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Products Grid
          Expanded(
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
                    actionLabel: query.search.isNotEmpty ? 'Reset Pencarian' : null,
                    onAction: query.search.isNotEmpty
                        ? () {
                            _searchController.clear();
                            ref.read(sellerProductQueryProvider.notifier).update((state) {
                              return state.copyWith(search: '', categoryId: '', page: 1);
                            });
                          }
                        : null,
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.xs,
                    AppSpacing.base,
                    AppSpacing.section,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onEdit: () => context.push('/umkm/products/edit/${product.id}'),
                      onDelete: () => _confirmDelete(product.id, product.name),
                      onToggleActive: (val) async {
                        final success = await ref
                            .read(productControllerProvider.notifier)
                            .updateProduct(id: product.id, isActive: val);
                        if (mounted && !success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal mengubah status aktif produk'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onTap: () => context.push('/umkm/products/detail/${product.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
