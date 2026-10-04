import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../controllers/product_controller.dart';
import '../../data/models/product_model.dart';
import '../../../../core/network/error_message.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../order/data/review_repository.dart';
import '../widgets/seller_page_ui.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
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
          content: Text(
            'Apakah Anda yakin ingin menghapus "${product.name}"? Tindakan ini tidak dapat dibatalkan.',
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
    final detailState = ref.watch(
      sellerProductDetailProvider(widget.productId),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: detailState.when(
        loading: () => const Center(child: AppleActivityIndicator(size: 28)),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Detail Produk')),
          body: ErrorStateWidget(
            errorMessage: err.toString(),
            onRetry: () =>
                ref.invalidate(sellerProductDetailProvider(widget.productId)),
          ),
        ),
        data: (product) {
          final isLowStock = product.stock <= 5;
          final statusColor = product.isApproved
              ? AppColors.success
              : AppColors.warning;
          final statusText = product.isApproved
              ? 'Disetujui Admin'
              : 'Menunggu Approval';

          return CustomScrollView(
            slivers: [
              // Beautiful SliverAppBar for Product Images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.canvas,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AppleGlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Kembali',
                    size: 40,
                    onTap: () => context.pop(),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: AppleGlassIconButton(
                      icon: Icons.edit_outlined,
                      semanticLabel: 'Edit produk',
                      size: 40,
                      onTap: () =>
                          context.push('/umkm/products/edit/${product.id}'),
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
                        const ProductImageLoader(
                          imageUrl: '',
                          fit: BoxFit.cover,
                        ),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: AppSpacing.md,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (idx) => AnimatedContainer(
                                duration: AppAnimation.fast,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _currentImageIndex == idx ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == idx
                                      ? AppColors.primary
                                      : AppColors.onDark.withValues(alpha: 0.6),
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
                child: SellerContentBoundary(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.base,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badges
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SellerStatusBadge(
                            label: statusText,
                            color: statusColor,
                            icon: product.isApproved
                                ? Icons.verified_rounded
                                : Icons.schedule_rounded,
                          ),
                          SellerStatusBadge(
                            label: product.isActive ? 'Aktif' : 'Nonaktif',
                            color: product.isActive
                                ? AppColors.success
                                : AppColors.muted,
                            icon: product.isActive
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
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
                      SellerSectionCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stok Tersedia',
                                  style: AppTypography.captionSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.stock} Unit',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isLowStock
                                        ? AppColors.errorText
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            SellerStatusBadge(
                              label: isLowStock ? 'Stok kritis' : 'Stok aman',
                              color: isLowStock
                                  ? AppColors.warning
                                  : AppColors.success,
                              icon: isLowStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
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

                      _ReviewSection(productId: widget.productId),
                      const SizedBox(height: AppSpacing.xl),

                      // Bottom actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(product),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.errorText,
                              ),
                              label: Text(
                                'Hapus Produk',
                                style: AppTypography.buttonSm.copyWith(
                                  color: AppColors.errorText,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.errorText,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(
                                '/umkm/products/edit/${product.id}',
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.onPrimary,
                              ),
                              label: Text(
                                'Edit Detail',
                                style: AppTypography.buttonSm.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
}

/// Ulasan pembeli — dari server, bukan dikarang.
///
/// Versi sebelumnya memilih isinya dengan `productId.hashCode % 2 == 0`:
/// separuh produk selalu menampilkan dua ulasan bintang lima dari nama yang
/// sama, separuh lagi selalu kosong. Penjual membaca itu sebagai umpan balik
/// pembeli sungguhan.
class _ReviewSection extends ConsumerWidget {
  final String productId;

  const _ReviewSection({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ReviewTarget.umkm(productId);
    final async = ref.watch(productReviewsProvider(target));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            // Rata-rata ikut datang dari endpoint yang sama, sudah dibulatkan
            // di server — supaya tidak ada dua layar yang membulatkan sendiri
            // lalu menampilkan angka yang sedikit berbeda.
            if (async.valueOrNull?.averageRating case final avg?)
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avg.toStringAsFixed(1),
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
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: AppleActivityIndicator(size: 22)),
          ),
          error: (error, _) => _ReviewNotice(
            icon: Icons.cloud_off_rounded,
            message: networkErrorMessage(error),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const _ReviewNotice(
                icon: Icons.rate_review_outlined,
                message: 'Belum ada ulasan untuk produk ini.',
              );
            }
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < page.items.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg),
                    _ReviewTile(review: page.items[i]),
                  ],
                  if (page.total > page.items.length) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '+${page.total - page.items.length} ulasan lainnya',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ReviewNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, color: AppColors.mutedSoft, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.reviewerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _relativeDate(review.createdAt),
              style: AppTypography.captionSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              Icons.star_rounded,
              color: index < review.rating
                  ? AppColors.warning
                  : AppColors.hairline,
              size: 16,
            ),
          ),
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            review.comment!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
          ),
        ],
      ],
    );
  }
}

/// Jarak waktu dalam bahasa Indonesia, ditulis tangan.
///
/// Bukan `DateFormat` berlokal `id_ID`: aplikasi ini tidak pernah memanggil
/// `initializeDateFormatting`, jadi lokal itu melempar LocaleDataException
/// saat dipakai.
String _relativeDate(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7} minggu lalu';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30} bulan lalu';
  return '${diff.inDays ~/ 365} tahun lalu';
}
