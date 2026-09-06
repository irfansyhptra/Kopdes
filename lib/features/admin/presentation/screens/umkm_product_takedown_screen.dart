import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../data/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';

// Admin Kopdes menurunkan (takedown) atau menayangkan kembali produk UMKM mitra.
class UmkmProductTakedownScreen extends ConsumerWidget {
  const UmkmProductTakedownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(umkmProductsProvider);
    final action = ref.watch(adminActionProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: adminAppBar(context, 'Moderasi Produk UMKM'),
          body: AdminAsyncList<UmkmProductAdmin>(
            value: products,
            onRefresh: () => ref.invalidate(umkmProductsProvider),
            emptyTitle: 'Belum ada produk UMKM.',
            emptyIcon: Icons.shopping_bag_outlined,
            itemBuilder: (p) => _ProductRow(product: p, ref: ref),
          ),
        ),
        ActionOverlay(visible: action is AsyncLoading),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final UmkmProductAdmin product;
  final WidgetRef ref;
  const _ProductRow({required this.product, required this.ref});

  Future<void> _toggle(BuildContext context, bool value) async {
    String? reason;
    if (!value) {
      // Takedown → minta alasan.
      // Dibuang di finally: dialog ini bukan milik State mana pun, jadi tidak
      // ada dispose() yang otomatis membersihkannya.
      final controller = TextEditingController();
      try {
        reason = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.canvas,
            title: Text(
              'Turunkan Produk',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Alasan takedown (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Turunkan'),
              ),
            ],
          ),
        );
      } finally {
        controller.dispose();
      }
      if (reason == null) return; // dibatalkan
    }
    final ok = await ref
        .read(adminActionProvider.notifier)
        .setProductActive(
          product.id,
          value,
          reason: reason?.isEmpty == true ? null : reason,
        );
    if (context.mounted) {
      showSnack(
        context,
        ok ? (value ? 'Produk ditayangkan' : 'Produk diturunkan') : 'Gagal',
        error: !ok,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: product.isActive ? AppColors.success : AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductImageLoader(
                  imageUrl: product.primaryImageUrl ?? '',
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  placeholderIconSize: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: AppColors.mutedSoft,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.umkmName,
                            style: AppTypography.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.body,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          rupiah(product.price),
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  Stok ${product.stock}',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairlineSoft, height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip(
                label: product.isActive
                    ? 'Tayang di App'
                    : 'Diturunkan (Moderasi)',
                color: product.isActive ? AppColors.success : AppColors.error,
                icon: product.isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              Row(
                children: [
                  Text(
                    product.isActive ? 'Tayang' : 'Takedown',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: product.isActive,
                      activeColor: AppColors.primary,
                      onChanged: (v) => _toggle(context, v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
