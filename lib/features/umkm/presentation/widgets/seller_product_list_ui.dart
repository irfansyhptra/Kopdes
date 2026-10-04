import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../data/models/product_category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/seller_product_page.dart';

/// Warna titik dan warna teks tiap status. Titik boleh terang; teks memakai
/// versi yang terbaca (≥4,5:1).
extension StockLevelColors on StockLevel {
  Color get dot => switch (this) {
    StockLevel.safe => AppColors.success,
    StockLevel.low => AppColors.warning,
    StockLevel.out => AppColors.error,
  };

  Color get text => switch (this) {
    StockLevel.safe => AppColors.successText,
    StockLevel.low => AppColors.warningText,
    StockLevel.out => AppColors.errorText,
  };
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────
// Filter kategori
// ─────────────────────────────────────────────────────────────

/// "Semua" + kategori toko, digulir mendatar, dengan tombol filter lanjutan
/// yang selalu terlihat di ujung kanan.
class CategoryFilterBar extends StatelessWidget {
  /// null = masih dimuat atau gagal: hanya "Semua" yang tampil, filter
  /// lain tetap bisa dipakai.
  final List<ProductCategoryModel>? categories;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool advancedActive;
  final VoidCallback onAdvanced;
  final EdgeInsets padding;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.advancedActive,
    required this.onAdvanced,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final items = categories ?? const <ProductCategoryModel>[];
    // Pil 36 di dalam area sentuh 44, ikut membesar bersama teks.
    final height = MediaQuery.textScalerOf(context).scale(44).clamp(44, 72);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height.toDouble(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: padding.left),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return AppleChip(
                    label: 'Semua',
                    selected: selectedId.isEmpty,
                    onTap: () => onSelect(''),
                  );
                }
                final c = items[i - 1];
                return AppleChip(
                  label: c.name,
                  selected: selectedId == c.id,
                  onTap: () => onSelect(c.id),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: EdgeInsets.only(right: padding.right),
          child: _FilterButton(active: advancedActive, onTap: onAdvanced),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: active
          ? 'Filter lanjutan, sedang aktif'
          : 'Filter lanjutan',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryTint : AppColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primarySoft : AppColors.hairline,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? AppColors.primaryText : AppColors.ink,
              ),
            ),
            // Penanda "aktif" bukan hanya warna: ada titik tambahan.
            if (active)
              const Positioned(
                top: 4,
                right: 4,
                child: _Dot(AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ringkasan
// ─────────────────────────────────────────────────────────────

/// "3 produk · 2 aman · 1 stok menipis". Status tetap disebut dengan kata,
/// warnanya hanya penegas.
class StockSummaryLine extends StatelessWidget {
  final StockSummary summary;

  /// Filter status yang sedang aktif, ditampilkan sebagai pil yang bisa
  /// dilepas — supaya daftar yang tersaring tidak terbaca seperti seluruh
  /// isi toko.
  final StockLevel? activeLevel;
  final VoidCallback? onClearLevel;

  const StockSummaryLine({
    super.key,
    required this.summary,
    this.activeLevel,
    this.onClearLevel,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.bodyMedium.copyWith(fontSize: 13.5);
    final parts = <InlineSpan>[
      TextSpan(
        text: '${summary.total} produk',
        style: base.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      for (final level in StockLevel.values.reversed)
        if (summary.of(level) > 0 || level == StockLevel.safe) ...[
          TextSpan(
            text: '  ·  ',
            style: base.copyWith(color: AppColors.mutedSoft),
          ),
          TextSpan(
            text: '${summary.of(level)} ${_word(level)}',
            style: base.copyWith(
              fontWeight: FontWeight.w600,
              color: level.text,
            ),
          ),
        ],
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Text.rich(TextSpan(children: parts)),
        if (activeLevel != null)
          _ActiveFilterPill(level: activeLevel!, onClear: onClearLevel),
      ],
    );
  }

  static String _word(StockLevel level) => switch (level) {
    StockLevel.safe => 'aman',
    StockLevel.low => 'stok menipis',
    StockLevel.out => 'habis',
  };
}

class _ActiveFilterPill extends StatelessWidget {
  final StockLevel level;
  final VoidCallback? onClear;

  const _ActiveFilterPill({required this.level, this.onClear});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onClear,
      semanticLabel: 'Filter stok ${level.label}. Ketuk untuk melepas',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Hanya ${level.label.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Baris produk
// ─────────────────────────────────────────────────────────────

enum SellerProductAction { view, edit, toggleActive, delete }

class SellerProductRow extends StatelessWidget {
  final ProductModel product;
  final StockLevel level;
  final VoidCallback onTap;
  final VoidCallback onAdjustStock;
  final ValueChanged<SellerProductAction> onAction;

  const SellerProductRow({
    super.key,
    required this.product,
    required this.level,
    required this.onTap,
    required this.onAdjustStock,
    required this.onAction,
  });

  /// Lebar minimum kolom teks sebelum "Atur stok" turun ke bawah, dalam dp
  /// pada skala teks 1,0×. Diukur: di bawah ini nama dua kata pun terpotong.
  static const double _minInfoWidth = 130;
  static const double _trailingWidth = 72;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final category = product.category?.name ?? 'Tanpa kategori';
    final status = [
      'Stok ${formatThousands(product.stock)}',
      level.label,
      if (!product.isActive) 'Nonaktif',
    ].join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumb = constraints.maxWidth >= 360 ? 72.0 : 64.0;
        final infoWidth =
            constraints.maxWidth -
            2 * AppSpacing.md -
            thumb -
            AppSpacing.md -
            _trailingWidth;
        final stacked = infoWidth < _minInfoWidth * scale;

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 15.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatRupiah(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                _Dot(product.isActive ? level.dot : AppColors.mutedSoft),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: product.isActive ? level.text : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        final menu = _RowMenu(
          productName: product.name,
          isActive: product.isActive,
          onSelected: onAction,
        );

        return ApplePressable(
          onTap: onTap,
          pressedScale: 0.985,
          semanticLabel:
              '${product.name}, $category, ${formatRupiah(product.price)}, '
              '$status. Buka detail',
          borderRadius: BorderRadius.circular(AppleRadii.tile),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.tile),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: ProductImageLoader(
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first.url
                            : '',
                        width: thumb,
                        height: thumb,
                        placeholderIconSize: 26,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: info),
                    if (stacked)
                      menu
                    else
                      SizedBox(
                        width: _trailingWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            menu,
                            _AdjustStockButton(onTap: onAdjustStock),
                          ],
                        ),
                      ),
                  ],
                ),
                if (stacked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _AdjustStockButton(
                      onTap: onAdjustStock,
                      horizontal: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RowMenu extends StatelessWidget {
  final String productName;
  final bool isActive;
  final ValueChanged<SellerProductAction> onSelected;

  const _RowMenu({
    required this.productName,
    required this.isActive,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SellerProductAction>(
      tooltip: 'Menu $productName',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppleRadii.control),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: SellerProductAction.view,
          child: _MenuLabel(Icons.visibility_outlined, 'Lihat'),
        ),
        const PopupMenuItem(
          value: SellerProductAction.edit,
          child: _MenuLabel(Icons.edit_outlined, 'Edit'),
        ),
        PopupMenuItem(
          value: SellerProductAction.toggleActive,
          child: _MenuLabel(
            isActive
                ? Icons.visibility_off_outlined
                : Icons.storefront_outlined,
            isActive ? 'Sembunyikan dari etalase' : 'Tampilkan di etalase',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SellerProductAction.delete,
          child: _MenuLabel(
            Icons.delete_outline_rounded,
            'Hapus',
            color: AppColors.errorText,
          ),
        ),
      ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuLabel(this.icon, this.label, {this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: AppSpacing.md),
      Flexible(
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: color),
        ),
      ),
    ],
  );
}

class _AdjustStockButton extends StatelessWidget {
  final VoidCallback onTap;

  /// Ikon dan label berdampingan — dipakai saat tombol turun ke bawah.
  final bool horizontal;

  const _AdjustStockButton({required this.onTap, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      'Atur stok',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.buttonSm.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    );
    const icon = Icon(
      Icons.add_rounded,
      size: 20,
      color: AppColors.primaryText,
    );

    return ApplePressable(
      onTap: onTap,
      semanticLabel: 'Atur stok',
      child: horizontal
          ? Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 6),
                  Flexible(child: label),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  ),
                  const SizedBox(height: 4),
                  label,
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton & keadaan
// ─────────────────────────────────────────────────────────────

/// Sebentuk [SellerProductRow] pada skala teks 1,0×.
class SellerProductRowSkeleton extends StatelessWidget {
  const SellerProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.tile),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 72, height: 72, borderRadius: 14),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 150, height: 15, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 11, borderRadius: 4),
                SizedBox(height: 10),
                ShimmerBox(width: 90, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 110, height: 11, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          ShimmerBox(width: 40, height: 40, borderRadius: 20),
        ],
      ),
    );
  }
}

/// Kosong, tanpa hasil, atau gagal — satu bentuk, beda isi.
class ProductListMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProductListMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.base),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
