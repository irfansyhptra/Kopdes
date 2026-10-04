import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../data/models/product_model.dart';
import '../../data/models/seller_product_page.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/product_controller.dart';
import '../widgets/seller_page_ui.dart';
import '../widgets/seller_product_list_ui.dart';
import '../widgets/stock_adjust_sheet.dart';
import '../widgets/stock_live_panel.dart';

/// Tab "Produk" pemilik UMKM: aktivitas stok, filter, ringkasan, daftar.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: ref.read(sellerProductQueryProvider).search,
  );
  Timer? _debounce;

  /// Lebar isi maksimal di tablet: baris produk yang membentang 1000dp
  /// memisahkan nama dari tombolnya terlalu jauh untuk dibaca sekali lirik.
  static const double _maxContentWidth = 720;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _updateQuery(ProductSearchQuery Function(ProductSearchQuery) f) =>
      ref.read(sellerProductQueryProvider.notifier).update(f);

  void _onSearchChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _updateQuery((q) => q.copyWith(search: text.trim()));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(_searchController.clear);
    _updateQuery((q) => q.copyWith(search: ''));
  }

  void _clearAllFilters() {
    _debounce?.cancel();
    setState(_searchController.clear);
    _updateQuery((_) => const ProductSearchQuery());
  }

  Future<void> _openAdvancedFilter(StockLevel? current) async {
    final picked = await showModalBottomSheet<_LevelChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppleRadii.card),
        ),
      ),
      builder: (_) => _StockFilterSheet(current: current),
    );
    if (picked == null) return;
    _updateQuery(
      (q) => picked.level == null
          ? q.copyWith(clearStockLevel: true)
          : q.copyWith(stockLevel: picked.level),
    );
  }

  Future<void> _adjustStock(ProductModel product, int threshold) async {
    final input = await showStockAdjustSheet(
      context,
      product: product,
      lowStockThreshold: threshold,
    );
    if (input == null || !mounted) return;

    final feedback = AppleFeedback.show(context, 'Menyimpan perubahan stok…');
    try {
      final stock = await ref
          .read(inventoryControllerProvider)
          .adjustStock(product.id, input.delta, reason: input.reason);
      final level = StockLevel.of(stock, threshold);
      await feedback.success(
        'Stok Tersimpan',
        'Stok "${product.name}" kini ${formatThousands(stock)} '
            '(${level.label.toLowerCase()}). Perubahan tercatat di riwayat.',
      );
    } catch (e) {
      await feedback.failure('Stok Belum Tersimpan', networkErrorMessage(e));
    }
  }

  Future<void> _onAction(ProductModel product, SellerProductAction action) {
    switch (action) {
      case SellerProductAction.view:
        return context.push('/umkm/products/detail/${product.id}');
      case SellerProductAction.edit:
        return context.push('/umkm/products/edit/${product.id}');
      case SellerProductAction.toggleActive:
        final show = !product.isActive;
        return runWithFeedback(
          context,
          waiting: show ? 'Menampilkan produk…' : 'Menyembunyikan produk…',
          action: () => ref
              .read(productControllerProvider.notifier)
              .updateProduct(id: product.id, isActive: show),
          successTitle: show ? 'Produk Tampil' : 'Produk Disembunyikan',
          successMessage: show
              ? '"${product.name}" kembali terlihat oleh pembeli.'
              : '"${product.name}" tidak lagi terlihat oleh pembeli. '
                    'Stok dan riwayatnya tetap tersimpan.',
          failureMessage: 'Status produk belum berubah. Coba lagi.',
        );
      case SellerProductAction.delete:
        return _confirmDelete(product);
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleRadii.tile),
        ),
        title: const Text('Hapus Produk?'),
        content: Text(
          '"${product.name}" akan dihapus dari toko Anda dan tidak bisa '
          'dikembalikan. Kalau hanya ingin berhenti menjualnya sementara, '
          'pilih "Sembunyikan dari etalase".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await runWithFeedback(
      context,
      waiting: 'Menghapus produk…',
      action: () => ref
          .read(productControllerProvider.notifier)
          .deleteProduct(product.id),
      successTitle: 'Produk Dihapus',
      successMessage: '"${product.name}" sudah tidak ada di toko Anda.',
      failureMessage: 'Produk belum terhapus. Periksa koneksi lalu coba lagi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeCategories = ref.watch(sellerStoreCategoriesProvider);
    // Jumlah di kepala = seluruh isi toko, apa pun filternya: dijumlah dari
    // kategori toko. Selagi belum ada, pakai ringkasan daftar bila tanpa
    // filter.
    final storeTotal = storeCategories.valueOrNull?.fold<int>(
      0,
      (sum, c) => sum + (c.productCount ?? 0),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SellerPageChrome(
        title: 'Produk Toko',
        subtitle: storeTotal == null
            ? 'Kelola etalase dan ketersediaan produk'
            : '$storeTotal produk di etalase Anda',
        actions: [
          GlassIconButton(
            icon: Icons.add_rounded,
            label: 'Tambah produk',
            onDark: true,
            onTap: () => context.push('/umkm/products/new'),
          ),
        ],
        headerChild: _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              0.0,
              (constraints.maxWidth - _maxContentWidth) / 2,
            );
            final pad = EdgeInsets.symmetric(
              horizontal: AppSpacing.base + side,
            );
            return _ProductList(
              padding: pad,
              onAdjustStock: _adjustStock,
              onAction: _onAction,
              onAdvancedFilter: _openAdvancedFilter,
              onClearFilters: _clearAllFilters,
            );
          },
        ),
      ),
    );
  }
}

/// Isi yang bergulir. Dipisah supaya ketikan di kolom pencarian (setState
/// di layar) tidak membangun ulang daftar.
class _ProductList extends ConsumerWidget {
  final EdgeInsets padding;
  final Future<void> Function(ProductModel, int threshold) onAdjustStock;
  final Future<void> Function(ProductModel, SellerProductAction) onAction;
  final ValueChanged<StockLevel?> onAdvancedFilter;
  final VoidCallback onClearFilters;

  const _ProductList({
    required this.padding,
    required this.onAdjustStock,
    required this.onAction,
    required this.onAdvancedFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(sellerProductQueryProvider);
    final listState = ref.watch(sellerProductListProvider);
    final categories = ref.watch(sellerStoreCategoriesProvider);
    final notifier = ref.read(sellerProductListProvider.notifier);
    // Bilah bawah mengambang di atas isi; produk terakhir harus bisa
    // digulir keluar dari bawahnya.
    final bottom = math.max(112.0, MediaQuery.paddingOf(context).bottom + 24);

    final slivers = <Widget>[
      SliverPadding(
        padding: padding.copyWith(top: AppSpacing.md),
        sliver: const SliverToBoxAdapter(child: StockActivityRow()),
      ),
      SliverPadding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        sliver: SliverToBoxAdapter(
          child: CategoryFilterBar(
            categories: categories.valueOrNull,
            selectedId: query.categoryId,
            padding: padding,
            onSelect: (id) => ref
                .read(sellerProductQueryProvider.notifier)
                .update((q) => q.copyWith(categoryId: id)),
            advancedActive: query.stockLevel != null,
            onAdvanced: () => onAdvancedFilter(query.stockLevel),
          ),
        ),
      ),
      ...listState.when(
        skipLoadingOnRefresh: true,
        loading: () => [
          SliverPadding(
            padding: padding.copyWith(top: AppSpacing.md),
            sliver: SliverList.separated(
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => i == 0
                  ? const ShimmerGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 220, height: 14, borderRadius: 4),
                          SizedBox(height: AppSpacing.md),
                          SellerProductRowSkeleton(),
                        ],
                      ),
                    )
                  : const ShimmerGroup(child: SellerProductRowSkeleton()),
            ),
          ),
        ],
        error: (error, _) => [
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: ProductListMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Produk Belum Termuat',
                message: networkErrorMessage(error),
                actionLabel: 'Coba Lagi',
                onAction: notifier.retry,
              ),
            ),
          ),
        ],
        data: (state) => _dataSlivers(context, ref, state, query),
      ),
      SliverToBoxAdapter(child: SizedBox(height: bottom)),
    ];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(sellerStoreCategoriesProvider);
        await notifier.refresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Halaman berikutnya diminta saat sisa gulir kurang dari ±satu
          // layar — penjaga di notifier mencegah permintaan ganda.
          if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) {
            notifier.loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: slivers,
        ),
      ),
    );
  }

  List<Widget> _dataSlivers(
    BuildContext context,
    WidgetRef ref,
    SellerProductListState state,
    ProductSearchQuery query,
  ) {
    void clearLevel() => ref
        .read(sellerProductQueryProvider.notifier)
        .update((q) => q.copyWith(clearStockLevel: true));

    if (state.items.isEmpty) {
      final Widget message;
      if (!query.isFiltered) {
        message = ProductListMessage(
          icon: Icons.inventory_2_outlined,
          title: 'Belum Ada Produk',
          message:
              'Tambahkan produk pertama Anda supaya pembeli di desa bisa '
              'menemukannya di marketplace.',
          actionLabel: 'Tambah Produk',
          onAction: () => context.push('/umkm/products/new'),
        );
      } else {
        message = ProductListMessage(
          icon: Icons.search_off_rounded,
          title: 'Tidak Ada yang Cocok',
          message: query.search.isNotEmpty
              ? 'Tidak ada produk "${query.search}" dengan filter ini. '
                    'Periksa ejaannya atau lepas filternya.'
              : 'Tidak ada produk dengan filter ini.',
          actionLabel: 'Hapus Pencarian & Filter',
          onAction: onClearFilters,
        );
      }
      return [
        if (query.isFiltered)
          SliverPadding(
            padding: padding.copyWith(top: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: StockSummaryLine(
                summary: state.summary,
                activeLevel: query.stockLevel,
                onClearLevel: clearLevel,
              ),
            ),
          ),
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(child: message),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: padding.copyWith(top: AppSpacing.md, bottom: AppSpacing.md),
        sliver: SliverToBoxAdapter(
          child: StockSummaryLine(
            summary: state.summary,
            activeLevel: query.stockLevel,
            onClearLevel: clearLevel,
          ),
        ),
      ),
      SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final product = state.items[i];
            return SellerProductRow(
              key: ValueKey(product.id),
              product: product,
              level: state.levelOf(product),
              onTap: () => context.push('/umkm/products/detail/${product.id}'),
              onAdjustStock: () =>
                  onAdjustStock(product, state.lowStockThreshold),
              onAction: (a) => onAction(product, a),
            );
          },
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.base),
            child: Center(child: AppleActivityIndicator(size: 22)),
          ),
        ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Cari produk di toko Anda',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
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
    );
  }
}

/// Hasil lembar filter. Dibungkus supaya "Semua" (null) bisa dibedakan dari
/// lembar yang ditutup tanpa memilih.
class _LevelChoice {
  final StockLevel? level;
  const _LevelChoice(this.level);
}

class _StockFilterSheet extends StatelessWidget {
  final StockLevel? current;

  const _StockFilterSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    Widget option(String label, String hint, StockLevel? level) {
      final selected = current == level;
      return ListTile(
        minTileHeight: 52,
        leading: level == null
            ? const Icon(Icons.all_inclusive_rounded, color: AppColors.muted)
            : Icon(Icons.circle, size: 12, color: level.dot),
        title: Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(hint),
        // Pilihan ditandai ikon centang, bukan warna saja.
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.primaryText)
            : null,
        selected: selected,
        onTap: () => Navigator.pop(context, _LevelChoice(level)),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Text(
                'Filter Status Stok',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            option('Semua status', 'Tampilkan semua produk', null),
            option('Aman', 'Stok di atas batas menipis', StockLevel.safe),
            option(
              'Menipis',
              'Masih ada, tapi perlu segera ditambah',
              StockLevel.low,
            ),
            option(
              'Habis',
              'Stok 0 — pembeli tidak bisa memesan',
              StockLevel.out,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
