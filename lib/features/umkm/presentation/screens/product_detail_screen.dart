import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../controllers/product_controller.dart';
import '../controllers/providers.dart';
import '../../data/models/product_model.dart';

final sellerProductDetailProvider = FutureProvider.family<ProductModel, String>((ref, id) async {
  final products = await ref.read(productRepositoryProvider).getProducts(limit: 100);
  return products.firstWhere(
    (p) => p.id == id,
    orElse: () => throw Exception('Produk tidak ditemukan'),
  );
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus Produk?'),
          content: Text('Apakah Anda yakin ingin menghapus "${product.name}"? Tindakan ini tidak dapat dibatalkan.'),
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
          .deleteProduct(product.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to products list
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
    final detailState = ref.watch(sellerProductDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Detail Produk')),
          body: ErrorStateWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(sellerProductDetailProvider(widget.productId)),
          ),
        ),
        data: (product) {
          final isLowStock = product.stock <= 5;
          final statusColor = product.isApproved ? AppColors.success : AppColors.warning;
          final statusText = product.isApproved ? 'Disetujui Admin' : 'Menunggu Approval';

          return CustomScrollView(
            slivers: [
              // Beautiful SliverAppBar for Product Images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.canvas,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.canvas.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                      onPressed: () => context.push('/umkm/products/edit/${product.id}'),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (product.images.isNotEmpty)
                        PageView.builder(
                          itemCount: product.images.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentImageIndex = idx;
                            });
                          },
                          itemBuilder: (context, idx) {
                            return ProductImageLoader(
                              imageUrl: product.images[idx].url,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      else
                        const ProductImageLoader(imageUrl: '', fit: BoxFit.cover),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: AppSpacing.md,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (idx) => AnimatedContainer(
                                duration: AppAnimation.fast,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == idx ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == idx
                                      ? AppColors.primary
                                      : AppColors.onDark.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content Area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  product.isApproved ? Icons.check_circle : Icons.pending,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: AppTypography.badge.copyWith(
                                    color: statusColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? AppColors.success.withOpacity(0.08)
                                  : AppColors.muted.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              product.isActive ? 'Status: Aktif' : 'Status: Nonaktif',
                              style: AppTypography.badge.copyWith(
                                color: product.isActive ? AppColors.success : AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Category & Title
                      Text(
                        product.category?.name ?? 'Kategori',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        product.name,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Price
                      Text(
                        'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stock details
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.hairlineSoft),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stok Tersedia', style: AppTypography.captionSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.stock} Unit',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isLowStock ? AppColors.errorText : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'Stok Kritis!',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'Stok Aman',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.success,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      Text(
                        'Deskripsi Produk',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Tidak ada deskripsi untuk produk ini.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.body,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Mock Review Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ulasan Pembeli',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                product.rating > 0
                                    ? product.rating.toStringAsFixed(1)
                                    : 'Belum ada',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMockReviews(),
                      const SizedBox(height: AppSpacing.xl),

                      // Bottom actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(product),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorText),
                              label: Text(
                                'Hapus Produk',
                                style: AppTypography.buttonSm.copyWith(color: AppColors.errorText),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.errorText),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/umkm/products/edit/${product.id}'),
                              icon: const Icon(Icons.edit_outlined, color: AppColors.onPrimary),
                              label: Text(
                                'Edit Detail',
                                style: AppTypography.buttonSm.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.section),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockReviews() {
    // Return mock review lists or a clean empty reviews indicator
    if (widget.productId.hashCode % 2 == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildReviewItem(
              name: 'Budi Santoso',
              rating: 5,
              comment: 'Barangnya sangat berkualitas, pengiriman cepat dan respon seller ramah!',
              date: '2 hari lalu',
            ),
            const Divider(height: AppSpacing.lg),
            _buildReviewItem(
              name: 'Siti Rahma',
              rating: 4,
              comment: 'Kualitas oke banget sesuai deskripsi. Cuma pengiriman agak terhambat dikit di kurir.',
              date: '1 minggu lalu',
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, color: AppColors.mutedSoft, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada ulasan untuk produk ini.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String comment,
    required String date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(date, style: AppTypography.captionSmall),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              Icons.star_rounded,
              color: index < rating ? Colors.orange : AppColors.hairline,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          comment,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
        ),
      ],
    );
  }
}
