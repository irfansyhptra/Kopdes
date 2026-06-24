import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/product/presentation/providers/product_provider.dart';
import 'package:kopdes/features/product/domain/entities/product.dart';
import 'package:kopdes/shared/widgets/product_image_loader.dart';

class AdminProductListScreen extends ConsumerWidget {
  const AdminProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final actionState = ref.watch(adminProductActionProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Kelola Produk',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: Text(
                  'Kategori',
                  style: AppTypography.buttonSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => context.push('/admin/categories'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.base),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductRow(context, ref, product);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      'Gagal memuat produk: $err',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminProductsProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/admin/products/new'),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Tambah Produk',
              style: AppTypography.buttonSm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),

        // Global loading overlay for mutative operations
        if (actionState is AsyncLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildProductRow(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairlineSoft),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppElevation.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          clipBehavior: Clip.antiAlias,
          child: ProductImageLoader(
            imageUrl: product.primaryImageUrl,
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            placeholderIconSize: 24,
          ),
        ),
        title: Text(
          product.name,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} | Stok: ${product.stock}',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: product.isActive
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.mutedSoft.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                product.isActive ? 'Aktif' : 'Nonaktif',
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: product.isActive ? AppColors.success : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Switch Toggle
            Switch(
              value: product.isActive,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                final success = await ref
                    .read(adminProductActionProvider.notifier)
                    .updateProduct(id: product.id, isActive: val);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Status produk "${product.name}" berhasil diubah',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            // Edit Button
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () =>
                  context.push('/admin/products/edit/${product.id}'),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context, ref, product),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Hapus Produk',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${product.name}"?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTypography.buttonSm.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminProductActionProvider.notifier)
                  .deleteProduct(product.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Produk "${product.name}" berhasil dihapus'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              'Hapus',
              style: AppTypography.buttonSm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum Ada Produk',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tekan tombol + di bawah untuk menambahkan produk pertama Anda.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
