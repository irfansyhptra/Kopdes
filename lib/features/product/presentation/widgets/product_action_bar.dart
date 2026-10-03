import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Bilah aksi mengambang di kaki halaman detail produk.
///
/// Tiga tombol dengan bobot berbeda: dua tombol ikon untuk tindakan pendukung,
/// dan satu tombol lebar bertuliskan harganya untuk tindakan utama. Harga
/// ditulis di tombolnya sendiri supaya yang ditekan dan yang dibayar tidak
/// perlu dicocokkan dengan menggulir ke atas lagi.
class ProductActionBar extends StatelessWidget {
  final double price;
  final bool outOfStock;
  final bool chatBusy;
  final VoidCallback onChat;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const ProductActionBar({
    super.key,
    required this.price,
    required this.onChat,
    required this.onAddToCart,
    required this.onBuyNow,
    this.outOfStock = false,
    this.chatBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.md + safeBottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
        boxShadow: AppElevation.floating,
      ),
      child: Row(
        children: [
          _IconAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Pesan',
            busy: chatBusy,
            onTap: onChat,
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconAction(
            icon: Icons.add_shopping_cart_rounded,
            label: 'Keranjang',
            onTap: outOfStock ? null : onAddToCart,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ApplePressable(
              onTap: outOfStock ? null : onBuyNow,
              semanticLabel: outOfStock
                  ? 'Stok habis'
                  : 'Beli sekarang ${rupiah.format(price)}',
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  // Stok habis dimatikan lewat warna DAN teks, bukan warna
                  // saja: tombol abu tanpa keterangan terbaca seperti galat.
                  color: outOfStock ? AppColors.hairline : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: outOfStock ? null : AppElevation.accent,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    outOfStock
                        ? 'Stok Habis'
                        : 'Beli Sekarang  ${rupiah.format(price)}',
                    maxLines: 1,
                    style: AppTypography.buttonSm.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: outOfStock
                          ? AppColors.mutedSoft
                          : AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;

    return ApplePressable(
      onTap: enabled ? onTap : null,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AppleRadii.control),
      child: SizedBox(
        // 56 lebar × 50 tinggi: target sentuhnya lega walau ikonnya kecil,
        // dan labelnya tetap muat di bawah ikon.
        width: 56,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.ink : AppColors.mutedSoft,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: enabled ? AppColors.body : AppColors.mutedSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
