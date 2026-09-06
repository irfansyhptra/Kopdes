import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/product/presentation/providers/product_provider.dart';
import 'package:kopdes/features/product/domain/entities/product.dart';
import 'package:kopdes/features/admin/presentation/widgets/admin_ui.dart';
import 'package:kopdes/shared/widgets/product_image_loader.dart';

class AdminProductListScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const AdminProductListScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<AdminProductListScreen> createState() =>
      _AdminProductListScreenState();
}

class _AdminProductListScreenState
    extends ConsumerState<AdminProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  static const List<String> _filters = [
    'Semua',
    'Aktif',
    'Stok Menipis',
    'Nonaktif',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final actionState = ref.watch(adminProductActionProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            elevation: 0,
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                    ),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/admin'),
                  )
                : null,
            automaticallyImplyLeading: widget.showBackButton,
            title: Text(
              'Kelola Barang Ritel',
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
              final filtered = _filterProducts(products);
              final activeCount = products.where((p) => p.isActive).length;
              final lowStockCount = products
                  .where((p) => p.stock > 0 && p.stock <= 5)
                  .length;
              final inactiveCount = products.where((p) => !p.isActive).length;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(adminProductsProvider),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  children: [
                    // Summary Banner Grid
                    Row(
                      children: [
                        Expanded(
                          child: _MetricBadge(
                            title: 'Total Barang',
                            value: '${products.length}',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetricBadge(
                            title: 'Barang Aktif',
                            value: '$activeCount',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricBadge(
                            title: 'Stok Menipis',
                            value: '$lowStockCount',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetricBadge(
                            title: 'Nonaktif',
                            value: '$inactiveCount',
                            icon: Icons.block_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang ritel...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Filter Choice Chips
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (context, idx) {
                          final f = _filters[idx];
                          final selected = _selectedFilter == f;
                          return ChoiceChip(
                            label: Text(f),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedFilter = f),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceSoft,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.hairlineSoft,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            labelStyle: AppTypography.captionSmall.copyWith(
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.body,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Products Count Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Barang (${filtered.length})',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedFilter != 'Semua')
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = 'Semua';
                              });
                            },
                            child: Text(
                              'Reset Filter',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Product Cards List
                    if (filtered.isEmpty)
                      _buildEmptyFilteredState()
                    else
                      ...filtered.map(
                        (product) => _buildProductCard(context, ref, product),
                      ),

                    const SizedBox(height: AppSpacing.section),
                  ],
                ),
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
                      textAlign: TextAlign.center,
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
              'Tambah Barang',
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

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case 'Aktif':
          return p.isActive;
        case 'Stok Menipis':
          return p.stock <= 5 && p.stock > 0;
        case 'Nonaktif':
          return !p.isActive;
        case 'Semua':
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final isLowStock = product.stock <= 5 && product.stock > 0;
    final isOutOfStock = product.stock == 0;

    return AdminCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: product.isActive
          ? (isOutOfStock
                ? AppColors.error
                : (isLowStock ? AppColors.warning : AppColors.success))
          : AppColors.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with anti-alias clip
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductImageLoader(
                  imageUrl: product.primaryImageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  placeholderIconSize: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title, Category, Price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rupiah(product.price),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Stock Pill & Status Chip
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (isOutOfStock)
                          const StatusChip(
                            label: 'Stok Habis',
                            color: AppColors.error,
                            icon: Icons.error_outline_rounded,
                          )
                        else if (isLowStock)
                          StatusChip(
                            label: 'Stok: ${product.stock} (Menipis)',
                            color: AppColors.warning,
                            icon: Icons.warning_amber_rounded,
                          )
                        else
                          StatusChip(
                            label: 'Stok: ${product.stock}',
                            color: AppColors.success,
                            icon: Icons.check_circle_outline,
                          ),
                        StatusChip(
                          label: product.isActive ? 'Aktif' : 'Nonaktif',
                          color: product.isActive
                              ? AppColors.primary
                              : AppColors.muted,
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

          // Action Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Status Tayang',
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
                      onChanged: (val) async {
                        final success = await ref
                            .read(adminProductActionProvider.notifier)
                            .updateProduct(id: product.id, isActive: val);
                        if (success && context.mounted) {
                          showSnack(
                            context,
                            'Status barang "${product.name}" berhasil diubah',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppColors.hairline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    label: Text(
                      'Edit',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () =>
                        context.push('/admin/products/edit/${product.id}'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    tooltip: 'Hapus Barang',
                    onPressed: () => _confirmDelete(context, ref, product),
                  ),
                ],
              ),
            ],
          ),
        ],
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
          'Hapus Barang',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus barang "${product.name}" dari katalog ritel?',
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminProductActionProvider.notifier)
                  .deleteProduct(product.id);
              if (success && context.mounted) {
                showSnack(context, 'Barang "${product.name}" berhasil dihapus');
              }
            },
            child: Text(
              'Hapus',
              style: AppTypography.buttonSm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.mutedSoft,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada barang ditemukan',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Coba ubah kata kunci atau ganti kriteria filter.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBadge({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
