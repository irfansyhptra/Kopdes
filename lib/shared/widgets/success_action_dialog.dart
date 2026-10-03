import 'package:flutter/material.dart';

import 'apple_feedback.dart';

/// Modal sukses dengan dua pilihan lanjutan.
///
/// Sekarang hanya pembungkus tipis di atas [showAppleActionDialog]. Versi
/// sebelumnya menggambar sendiri kartunya lengkap dengan warna hijau dan radius
/// yang ditulis tetap — sistem modal kedua yang menyimpang dari token begitu
/// paletnya berubah.
void showSuccessActionDialog(
  BuildContext context, {
  required String title,
  required String description,
  String primaryButtonLabel = 'Lihat Keranjang',
  required VoidCallback onPrimaryPressed,
  String secondaryButtonLabel = 'Kembali',
  required VoidCallback onSecondaryPressed,
  Widget? customIcon,
}) {
  showAppleActionDialog<void>(
    context,
    title: title,
    message: description,
    icon: customIcon,
    primaryLabel: primaryButtonLabel,
    onPrimary: onPrimaryPressed,
    secondaryLabel: secondaryButtonLabel,
    onSecondary: onSecondaryPressed,
  );
}
