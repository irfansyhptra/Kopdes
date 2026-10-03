import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/entities/order.dart';
import '../../data/review_repository.dart';
import 'review_sheet.dart';
import '../../domain/order_status_view.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'cart_seller_group.dart';
import 'orders_chrome.dart';

/// Kartu ringkas satu pesanan, dipakai tab Diproses maupun Selesai.
///
/// Tindakan yang ditawarkan diturunkan dari status pesanan, bukan dari daftar
/// tombol tetap: pemesan tidak boleh bisa menggeser statusnya sendiri, hanya
/// menyelesaikan langkah yang memang giliran dia.
class OrderStatusCard extends ConsumerWidget {
  final Order order;

  /// Tab Selesai menampilkan "Beli Lagi"; tab Diproses menampilkan lacak,
  /// bayar, atau konfirmasi terima.
  final bool finished;

  const OrderStatusCard({
    super.key,
    required this.order,
    this.finished = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = order.statusView;
    final seller = order.primarySeller;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppleCard(
        radius: AppleRadii.tile,
        clip: false,
        onTap: () => context.push('/orders/${order.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.displayNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (seller != null) ...[
                            SellerTypeChip(seller: seller),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              _sellerLine(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall.copyWith(
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusPill(view: view),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Thumbnails(order: order),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dateLabel(order.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(order.totalAmount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        order.paymentLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Actions(order: order, finished: finished),
          ],
        ),
      ),
    );
  }

  String _sellerLine() {
    final seller = order.primarySeller;
    if (seller == null) return 'Pesanan';
    final extra = order.sellerCount - 1;
    return extra > 0 ? '${seller.label} +$extra toko' : seller.label;
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _dateLabel(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}

class _StatusPill extends StatelessWidget {
  final OrderStatusView view;

  const _StatusPill({required this.view});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = view.isCancelled
        ? (AppColors.surfaceSoft, AppColors.muted)
        : view.isActive
        ? (AppColors.primaryTint, AppColors.primary)
        : (SellerBadgeColors.kopdesSurface, SellerBadgeColors.kopdesText);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 132),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          view.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Maksimal tiga gambar; sisanya diringkas menjadi "+n".
class _Thumbnails extends StatelessWidget {
  final Order order;

  const _Thumbnails({required this.order});

  @override
  Widget build(BuildContext context) {
    final shown = order.items.take(3).toList();
    final extra = order.items.length - shown.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppleRadii.control),
              child: SizedBox(
                width: 44,
                height: 44,
                child: ColoredBox(
                  color: AppColors.surfaceSoft,
                  child: ProductImageLoader(
                    imageUrl: item.imageUrl,
                    placeholderIconSize: 16,
                  ),
                ),
              ),
            ),
          ),
        if (extra > 0)
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppleRadii.control),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Text(
              '+$extra',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.body,
              ),
            ),
          ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  final Order order;
  final bool finished;

  const _Actions({required this.order, required this.finished});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Saat pesanan sedang diantar, tombol yang sama diberi label "Lacak
    // Pesanan": halaman detail memuat lini masa pengirimannya. Rute
    // `/tracking/:id` sengaja tidak dipakai — rute itu menuntut deliveryId,
    // sedangkan `/orders/history` tidak mengembalikan relasi pengiriman, jadi
    // mengirim id pesanan ke sana akan membuka halaman yang salah.
    final buttons = <Widget>[
      _OrderButton(
        label: order.canTrack ? 'Lacak Pesanan' : 'Lihat Detail',
        onTap: () => context.push('/orders/${order.id}'),
      ),
    ];

    if (finished) {
      buttons.add(
        _OrderButton(
          label: 'Beli Lagi',
          primary: true,
          onTap: () => _reorder(context, ref),
        ),
      );
      // "Beri Ulasan" hanya muncul bila server memang menyisakan produk
      // yang belum diulas pada pesanan ini. Tombol yang selalu tampil lalu
      // dijawab 409 "sudah pernah diulas" lebih buruk daripada tidak ada.
      if (order.statusView.isCancelled == false) {
        final reviewable = ref
            .watch(reviewableItemsProvider(order.id))
            .valueOrNull;
        if (reviewable != null && reviewable.isNotEmpty) {
          buttons.add(
            _OrderButton(
              label: 'Beri Ulasan',
              onTap: () => showReviewSheet(context, order.id, reviewable),
            ),
          );
        }
      }
    } else {
      if (order.isAwaitingPayment) {
        buttons.add(
          _OrderButton(
            label: 'Bayar Sekarang',
            primary: true,
            onTap: () => context.push('/orders/${order.id}'),
          ),
        );
      }
      if (order.canConfirmReceipt) {
        buttons.add(
          _OrderButton(
            label: 'Konfirmasi Diterima',
            primary: true,
            onTap: () => _confirmReceipt(context, ref),
          ),
        );
      }
    }

    // Wrap, bukan Row: pada teks besar tombol-tombol ini turun baris alih-alih
    // meluber ke luar kartu.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    );
  }

  Future<void> _confirmReceipt(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(orderActionProvider.notifier)
        .updateStatus(order.id, 'COMPLETED');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Pesanan ditandai diterima' : 'Konfirmasi belum tersimpan',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// "Beli Lagi" mengisi ulang keranjang dari baris pesanan lama, lalu
  /// memindahkan pengguna ke tab Keranjang — bukan langsung memesan, karena
  /// harga dan stok bisa sudah berubah sejak pesanan itu.
  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    var added = 0;
    for (final item in order.items) {
      final ok = await ref
          .read(cartProvider.notifier)
          .addToCart(
            productId: item.productId,
            umkmProductId: item.umkmProductId,
            quantity: item.quantity,
            productName: item.name,
          );
      if (ok) added++;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Produk tidak lagi tersedia'
                : added == order.items.length
                ? '$added produk ditambahkan ke keranjang'
                : '$added dari ${order.items.length} produk ditambahkan',
          ),
          backgroundColor: added == 0 ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _OrderButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _OrderButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: label,
      child: Container(
        // Target sentuh penuh: tombol-tombol ini memicu tindakan yang tidak
        // sepele (membayar, menandai pesanan diterima).
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppleRadii.control),
          border: Border.all(
            color: primary ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.buttonSm.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primary ? AppColors.onPrimary : AppColors.body,
          ),
        ),
      ),
    );
  }
}
