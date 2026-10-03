import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/apple_feedback.dart';

/// Menambah barang ke keranjang dengan modal tunggu lalu modal hasil.
///
/// Urutannya dulu disalin di lima layar — beranda, marketplace, etalase toko,
/// detail produk mitra, dan lembar pembelian — masing-masing dengan
/// perbedaan kecilnya sendiri: ada yang menampilkan SnackBar saat gagal, ada
/// yang tidak menampilkan apa-apa selama menunggu. Satu tempat berarti satu
/// perilaku, dan layar berikutnya tidak bisa lupa salah satu langkahnya.
///
/// [add] mengembalikan `true` bila barangnya benar-benar masuk.
Future<bool> addToCartWithFeedback(
  BuildContext context, {
  required String productName,
  required Future<bool> Function() add,
}) {
  return runWithFeedback(
    context,
    waiting: 'Menambahkan ke keranjang…',
    action: add,
    failureTitle: 'Gagal menambahkan',
    failureMessage: '$productName belum masuk keranjang. Coba lagi.',
    // Tanpa judul sukses: dialog di bawah yang menggantikannya, karena ia
    // menawarkan langkah berikutnya alih-alih sekadar mengabarkan.
    onSuccess: () async {
      if (!context.mounted) return;
      await showAppleActionDialog<void>(
        context,
        title: 'Masuk keranjang',
        message: '$productName sudah ditambahkan.',
        primaryLabel: 'Lihat Keranjang',
        onPrimary: () {
          Navigator.of(context).pop();
          context.go('/cart');
        },
        secondaryLabel: 'Lanjut Belanja',
        onSecondary: () => Navigator.of(context).pop(),
      );
    },
  );
}
