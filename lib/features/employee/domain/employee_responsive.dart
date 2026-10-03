import 'package:flutter/foundation.dart';

/// Kelas ukuran layar dashboard pegawai.
///
/// Dipisah dari `MediaQuery` supaya widget uji bisa memasang lebar apa pun
/// tanpa menyiapkan seluruh pohon aplikasi, dan supaya satu keputusan tata
/// letak tidak tersebar sebagai `if (width < 600)` di belasan widget.
enum KopdesLayoutSize { compact, phone, tablet, large }

@immutable
class KopdesResponsiveSpec {
  const KopdesResponsiveSpec({
    required this.size,
    required this.pagePadding,
    required this.quickActionColumns,
    required this.kpiColumns,
    required this.maxContentWidth,
    required this.useSideNavigation,
  });

  final KopdesLayoutSize size;
  final double pagePadding;
  final int quickActionColumns;
  final int kpiColumns;
  final double maxContentWidth;
  final bool useSideNavigation;

  factory KopdesResponsiveSpec.fromWidth(double width) {
    if (width < 360) {
      return const KopdesResponsiveSpec(
        size: KopdesLayoutSize.compact,
        pagePadding: 12,
        // Dua kolom, bukan tiga: pada 320dp dengan skala teks besar, label
        // tiga kolom sudah terpotong sebelum ikonnya sempat terbaca.
        quickActionColumns: 2,
        kpiColumns: 2,
        maxContentWidth: double.infinity,
        useSideNavigation: false,
      );
    }

    if (width < 600) {
      return const KopdesResponsiveSpec(
        size: KopdesLayoutSize.phone,
        pagePadding: 16,
        quickActionColumns: 4,
        kpiColumns: 4,
        maxContentWidth: double.infinity,
        useSideNavigation: false,
      );
    }

    if (width < 1024) {
      return const KopdesResponsiveSpec(
        size: KopdesLayoutSize.tablet,
        pagePadding: 24,
        quickActionColumns: 4,
        kpiColumns: 4,
        maxContentWidth: 960,
        useSideNavigation: true,
      );
    }

    return const KopdesResponsiveSpec(
      size: KopdesLayoutSize.large,
      pagePadding: 32,
      quickActionColumns: 8,
      kpiColumns: 4,
      maxContentWidth: 1120,
      useSideNavigation: true,
    );
  }

  bool get isCompact => size == KopdesLayoutSize.compact;
  bool get isPhoneOrSmaller =>
      size == KopdesLayoutSize.compact || size == KopdesLayoutSize.phone;

  /// Stok & keuangan berdampingan hanya bila kolomnya masih layak dibaca.
  bool get sideBySideInsights => !isCompact;
}
