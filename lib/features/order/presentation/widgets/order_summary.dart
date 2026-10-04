import 'package:flutter/material.dart';
import 'package:kopdes/core/theme/theme.dart';

import '../../domain/order_totals.dart';

/// Rincian pembayaran sebuah pesanan atau calon pesanan.
///
/// Menerima komponen yang sudah jadi, bukan menghitung tambahannya sendiri.
/// Versi sebelumnya menambahkan biaya layanan Rp2.000 secara tetap di dalam
/// widget, sehingga setiap layar yang memakainya menampilkan total yang tidak
/// pernah ditagihkan backend.
class OrderSummary extends StatelessWidget {
  final OrderTotals totals;

  /// Keterangan kecil di bawah rincian, mis. penjelasan ongkir gratis.
  final String? note;

  const OrderSummary({super.key, required this.totals, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Pembayaran',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Line(label: 'Subtotal Produk', value: formatRupiah(totals.subtotal)),
        const SizedBox(height: AppSpacing.sm),
        _Line(label: 'Ongkos Kirim', value: totals.shippingLabel),
        // Diskon hanya muncul kalau memang ada potongannya. Baris "-Rp0"
        // terbaca sebagai promo yang gagal dipakai, bukan sebagai tidak ada
        // promo.
        if (totals.hasDiscount) ...[
          const SizedBox(height: AppSpacing.sm),
          _Line(
            label: 'Diskon',
            value: '-${formatRupiah(totals.effectiveDiscount)}',
            valueColor: AppColors.success,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        // Wrap, bukan Row: pada layar sempit atau teks besar nominal turun
        // ke baris berikutnya alih-alih meluber.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          children: [
            Text(
              'Total Pembayaran',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              formatRupiah(totals.total),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            note!,
            style: AppTypography.captionSmall.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
