import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/widgets/apple_ui.dart';

/// Palet dashboard Pegawai Kopdes.
///
/// Terpisah dari `AppColors` karena dashboard staf memakai identitas Merah
/// Putih yang lebih pekat daripada etalase pelanggan; menggabungkannya akan
/// mengubah warna seluruh aplikasi pembeli.
class KopdesEmployeeColors {
  static const primary = AppColors.primary;
  static const darkRed = AppColors.darkRed;
  static const brightRed = AppColors.brightRed;
  static const background = AppColors.surfaceSoft;
  static const surface = AppColors.canvas;
  static const textPrimary = AppColors.ink;
  static const textSecondary = AppColors.muted;
  static const divider = AppColors.hairlineSoft;
  static const success = Color(0xFF159455);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2878D0);
  static const purple = Color(0xFF7442C8);

  /// Latar pastel untuk tile Akses Cepat — cukup lembut agar ikon berwarna
  /// tetap kontras di atasnya.
  static Color tint(Color color) =>
      Color.alphaBlend(color.withValues(alpha: 0.12), surface);
}

class KopdesSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class KopdesRadii {
  static const double surface = AppRadius.card;
  static const double tile = AppRadius.lg;
  static const double bottomNav = 24;
  static const double pill = 999;
}

/// Batas baca untuk halaman operasional Kopdes di ponsel dan tablet.
class KopdesContentBoundary extends StatelessWidget {
  const KopdesContentBoundary({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 920,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AppleContentBoundary(
      maxWidth: maxWidth,
      padding: padding,
      child: child,
    );
  }
}

/// Kartu putih dengan sudut lembut — dipakai KPI, pesanan, stok, keuangan.
class KopdesSurface extends StatelessWidget {
  const KopdesSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KopdesSpacing.base),
    this.radius = KopdesRadii.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: KopdesEmployeeColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: KopdesEmployeeColors.divider, width: 0.5),
        boxShadow: AppElevation.soft,
      ),
      child: child,
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan.
class KopdesSectionHeader extends StatelessWidget {
  const KopdesSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KopdesEmployeeColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: KopdesSpacing.sm),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KopdesEmployeeColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Blok abu berdenyut untuk keadaan memuat.
///
/// Ukurannya disamakan dengan widget aslinya supaya tata letak tidak melompat
/// begitu data datang — itulah alasan skeleton dipakai, bukan spinner.
class KopdesSkeleton extends StatelessWidget {
  const KopdesSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EA),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Pesan gagal muat satu bagian, lengkap dengan tombol coba lagi.
///
/// Per bagian, bukan per halaman: rekap keuangan yang gagal tidak boleh
/// menghapus daftar pesanan yang sudah berhasil dimuat.
class KopdesSectionError extends StatelessWidget {
  const KopdesSectionError({
    super.key,
    required this.onRetry,
    this.message = 'Data operasional belum berhasil dimuat',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return KopdesSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: KopdesEmployeeColors.textSecondary,
            ),
          ),
          const SizedBox(height: KopdesSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KopdesEmployeeColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
