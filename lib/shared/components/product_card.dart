import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../features/umkm/data/models/product_model.dart';
import '../widgets/apple_feedback.dart';
import '../widgets/apple_ui.dart';
import '../widgets/product_image_loader.dart';

/// Kartu produk di konsol penjual.
///
/// Mendatar: gambar seperempat lebar di kiri setinggi kartu, sisanya rincian
/// dan kendali di kanan. Versi sebelumnya menumpuk gambar-lalu-teks-lalu
/// sebaris tombol selebar kartu, dan di layar sempit baris tombol itu — satu
/// Switch dan dua tombol 44px, 139px perabot tetap — tidak pernah muat.
///
/// Kendali stok ada di sini juga: halaman Stok yang terpisah dilebur, karena
/// menambah satu barang berarti berpindah halaman untuk melakukan hal yang
/// sudah jelas ada di depan mata.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueSetter<bool>? onToggleActive;

  /// Penyesuaian stok: +1 atau −1. Null menyembunyikan kendalinya.
  final ValueSetter<int>? onAdjustStock;
  final bool stockBusy;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.onAdjustStock,
    this.stockBusy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first.url : '';

    return AppleCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seperempat lebar kartu, setinggi kartu. Flex, bukan angka tetap:
          // kartunya satu kolom di ponsel dan dua di tablet.
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppleRadii.card),
              ),
              child: ColoredBox(
                color: AppColors.surfaceSoft,
                child: ProductImageLoader(imageUrl: imageUrl),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: _Details(
                product: product,
                onEdit: onEdit,
                onDelete: onDelete,
                onToggleActive: onToggleActive,
                onAdjustStock: onAdjustStock,
                stockBusy: stockBusy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueSetter<bool>? onToggleActive;
  final ValueSetter<int>? onAdjustStock;
  final bool stockBusy;

  const _Details({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onAdjustStock,
    required this.stockBusy,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = product.stock <= 0;
    final isLow = product.stock > 0 && product.stock <= 5;
    final (Color stockColor, String stockLabel) = isOut
        ? (AppColors.errorText, 'Habis')
        : isLow
        ? (AppColors.warning, 'Menipis')
        : (AppColors.muted, 'Aman');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            // Wrap: pada skala teks besar lencana dan kategori tidak muat
            // sebaris, dan keduanya harus tetap utuh terbaca.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                // Berteks, bukan titik berwarna. Versi sebelumnya
                // mengandalkan Tooltip — yang tidak pernah muncul pada
                // sentuhan, jadi pengguna awas berjari tidak punya cara apa
                // pun mengetahui artinya.
                if (!product.isApproved) ...[
                  const AppleBadge(
                    label: 'Belum tayang',
                    color: AppColors.warning,
                  ),
                ],
                Text(
                  '${product.category?.name ?? 'Tanpa kategori'} · $stockLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 11.5,
                    color: stockColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatRupiah(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ControlRow(
          product: product,
          onEdit: onEdit,
          onDelete: onDelete,
          onToggleActive: onToggleActive,
          onAdjustStock: onAdjustStock,
          stockBusy: stockBusy,
        ),
      ],
    );
  }
}

/// Stok dan aksi dalam satu baris di kolom kanan — tidak ditumpuk di bawah
/// kartu, tempat ia dulu tidak pernah muat.
class _ControlRow extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueSetter<bool>? onToggleActive;
  final ValueSetter<int>? onAdjustStock;
  final bool stockBusy;

  const _ControlRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onAdjustStock,
    required this.stockBusy,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap, bukan Row: pengatur stok (102px) dan tiga tombol (108px) butuh
    // 210px, sedangkan kolom kanan kartu di layar 320dp hanya 192px. Dipaksa
    // sebaris ia meluber; dibiarkan membungkus, ia turun sendiri ke baris
    // kedua di ponsel sempit dan tetap sebaris begitu ada ruang.
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (onAdjustStock != null)
          _StockStepper(
            stock: product.stock,
            busy: stockBusy,
            onAdjust: onAdjustStock!,
          ),
        if (onToggleActive != null)
          _Tap(
            icon: product.isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            tooltip: product.isActive
                ? 'Sembunyikan produk'
                : 'Tayangkan produk',
            color: product.isActive ? AppColors.muted : AppColors.mutedSoft,
            onTap: () => onToggleActive!(!product.isActive),
          ),
        if (onEdit != null)
          _Tap(
            icon: Icons.edit_outlined,
            tooltip: 'Ubah produk',
            color: AppColors.muted,
            onTap: onEdit!,
          ),
        if (onDelete != null)
          _Tap(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Hapus produk',
            color: AppColors.errorText,
            onTap: onDelete!,
          ),
      ],
    );
  }
}

/// Pengatur stok ringkas: kurang, angka, tambah.
class _StockStepper extends StatelessWidget {
  final int stock;
  final bool busy;
  final ValueSetter<int> onAdjust;

  const _StockStepper({
    required this.stock,
    required this.busy,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 46, bukan 44: borosnya 1px tepi di atas dan bawah, jadi tombol di
      // dalamnya tinggal 42 — di bawah batas HIG.
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Kurangi stok',
            // Stok nol tidak bisa dikurangi — server menolaknya, jadi
            // tombolnya dimatikan lebih dulu daripada memunculkan error.
            onTap: busy || stock <= 0 ? null : () => onAdjust(-1),
          ),
          SizedBox(
            width: 36,
            child: busy
                ? const Center(child: AppleActivityIndicator(size: 13))
                : Text(
                    '$stock',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'Tambah stok',
            onTap: busy ? null : () => onAdjust(1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          // 44 tinggi penuh pengatur stok; lebarnya 40 supaya dua tombol
          // plus angkanya tetap muat di kolom kanan kartu.
          width: 40,
          height: 44,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.mutedSoft : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon: lambangnya 19px, area sentuhnya 44×44 — batas Apple HIG.
///
/// Sempat 38×38 demi memuat empat kendali dalam satu baris. Itu salah
/// tukar: yang boleh ringkas adalah tampilannya, bukan area sentuhnya.
/// Konsekuensinya kendali lebih sering membungkus ke baris kedua di layar
/// sempit, dan itu memang harga yang benar untuk dibayar.
class _Tap extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _Tap({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
