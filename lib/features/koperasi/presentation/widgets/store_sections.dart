import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../marketplace/domain/marketplace.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../marketplace/presentation/widgets/marketplace_product_card.dart';
import '../../../order/presentation/cart_feedback.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../providers/koperasi_store_provider.dart';

/// Bagian etalase yang sama persis untuk Kopdes dan Mitra UMKM: pencarian di
/// dalam toko, baris filter, dan grid produknya.
///
/// Dipisah ke sini supaya kedua halaman benar-benar memakai satu susunan —
/// bukan dua salinan yang lama-lama menyimpang.

// ─────────────────────────────────────────────────────────────
// Cari di dalam toko
// ─────────────────────────────────────────────────────────────

class StoreSearchField extends ConsumerStatefulWidget {
  final StoreRef store;

  const StoreSearchField({required this.store});

  @override
  ConsumerState<StoreSearchField> createState() => StoreSearchFieldState();
}

class StoreSearchFieldState extends ConsumerState<StoreSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(storeSearchProvider(widget.store)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    ref.read(storeSearchProvider(widget.store).notifier).state = value.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.base,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppleSectionHeader(
            title: 'Barang di Toko Ini',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            // Dikirim saat selesai mengetik, bukan tiap huruf: daftar ini
            // sudah disaring satu toko, jadi hasilnya sedikit dan pencarian
            // per huruf hanya menambah permintaan tanpa mengubah apa pun yang
            // terlihat.
            onSubmitted: _submit,
            style: AppTypography.bodyMedium.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari barang di toko ini…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _controller.clear();
                          _submit('');
                        },
                      ),
              ),
              filled: true,
              fillColor: AppColors.canvas,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppleRadii.control + 5),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppleRadii.control + 5),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppleRadii.control + 5),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter
// ─────────────────────────────────────────────────────────────

class StoreFilterRow extends ConsumerWidget {
  final StoreRef store;

  const StoreFilterRow({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final selected = ref.watch(storeCategoryProvider(store));
    final inStockOnly = ref.watch(storeInStockOnlyProvider(store));

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          children: [
            AppleChip(
              label: 'Semua',
              selected: selected == null,
              onTap: () =>
                  ref.read(storeCategoryProvider(store).notifier).state = null,
            ),
            const SizedBox(width: AppSpacing.sm),
            AppleChip(
              label: 'Ada Stok',
              selected: inStockOnly,
              onTap: () =>
                  ref.read(storeInStockOnlyProvider(store).notifier).state =
                      !inStockOnly,
            ),
            for (final Category category in categories) ...[
              const SizedBox(width: AppSpacing.sm),
              AppleChip(
                label: category.name,
                selected: selected == category.id,
                onTap: () =>
                    ref.read(storeCategoryProvider(store).notifier).state =
                        selected == category.id ? null : category.id,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Produk
// ─────────────────────────────────────────────────────────────

class StoreProductGrid extends ConsumerWidget {
  final StoreRef store;

  const StoreProductGrid({required this.store});

  /// Menambah ke keranjang langsung dari etalase.
  ///
  /// Memakai provider keranjang yang sama dengan Marketplace; yang tidak boleh
  /// terjadi adalah tombol "+" di sini hanya membuka halaman detail, karena
  /// bentuk tombolnya menjanjikan barangnya langsung masuk.
  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    MarketplaceProduct product,
  ) async {
    final adding = ref.read(addingToCartProvider);
    if (adding.contains(product.id)) return;
    ref.read(addingToCartProvider.notifier).state = {...adding, product.id};

    await addToCartWithFeedback(
      context,
      productName: product.name,
      add: () => ref
          .read(cartProvider.notifier)
          .addToCart(
            productId: product.isUmkm ? null : product.id,
            umkmProductId: product.isUmkm ? product.id : null,
            quantity: 1,
            productName: product.name,
          ),
    );

    if (!context.mounted) return;
    ref.read(addingToCartProvider.notifier).state = {
      ...ref.read(addingToCartProvider),
    }..remove(product.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeProductsProvider(store));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        0,
      ),
      sliver: async.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: AppleActivityIndicator()),
          ),
        ),
        error: (_, __) => SliverToBoxAdapter(
          child: StoreEmptyState(
            icon: Icons.wifi_off_rounded,
            message: 'Barang toko ini belum berhasil dimuat.',
          ),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const SliverToBoxAdapter(
              child: StoreEmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'Tidak ada barang yang cocok dengan pencarianmu.',
              ),
            );
          }

          return SliverGrid.builder(
            gridDelegate: marketplaceGridDelegate(context),
            itemCount: page.items.length,
            itemBuilder: (context, index) {
              final product = page.items[index];
              return MarketplaceProductCard(
                product: product,
                onTap: () => context.push('/products/detail/${product.id}'),
                onAddToCart: () => _addToCart(context, ref, product),
              );
            },
          );
        },
      ),
    );
  }
}

class StoreEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const StoreEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.mutedSoft),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
