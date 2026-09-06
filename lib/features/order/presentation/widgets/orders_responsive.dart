import 'package:flutter/material.dart';

/// Ukuran tata letak halaman Pesanan.
enum OrdersLayoutSize { compact, phone, tablet, large }

/// Ukuran-ukuran yang diturunkan dari lebar yang benar-benar tersedia.
///
/// Diturunkan dari `constraints`, bukan dari `MediaQuery`: pada tablet halaman
/// ini dipakai di dalam kolom yang lebih sempit daripada layar, dan ukuran
/// yang diambil dari layar akan salah di situ.
@immutable
class OrdersSpec {
  final OrdersLayoutSize layout;
  final double pagePadding;
  final double contentMaxWidth;
  final double thumbnailSize;

  /// True bila daftar dan Ringkasan Belanja muat berdampingan.
  final bool splitLayout;

  final double summaryWidth;

  const OrdersSpec({
    required this.layout,
    required this.pagePadding,
    required this.contentMaxWidth,
    required this.thumbnailSize,
    required this.splitLayout,
    required this.summaryWidth,
  });

  factory OrdersSpec.fromWidth(double width) {
    if (width < 360) {
      return const OrdersSpec(
        layout: OrdersLayoutSize.compact,
        pagePadding: 12,
        contentMaxWidth: double.infinity,
        thumbnailSize: 66,
        splitLayout: false,
        summaryWidth: double.infinity,
      );
    }
    if (width < 600) {
      return const OrdersSpec(
        layout: OrdersLayoutSize.phone,
        pagePadding: 16,
        contentMaxWidth: double.infinity,
        thumbnailSize: 76,
        splitLayout: false,
        summaryWidth: double.infinity,
      );
    }
    if (width < 1024) {
      return const OrdersSpec(
        layout: OrdersLayoutSize.tablet,
        pagePadding: 24,
        contentMaxWidth: 960,
        thumbnailSize: 84,
        splitLayout: true,
        summaryWidth: 320,
      );
    }
    return const OrdersSpec(
      layout: OrdersLayoutSize.large,
      pagePadding: 32,
      contentMaxWidth: 1120,
      thumbnailSize: 92,
      splitLayout: true,
      summaryWidth: 360,
    );
  }

  bool get isCompact => layout == OrdersLayoutSize.compact;

  /// Pada layar pendek, Ringkasan Belanja terbuka penuh memakan hampir
  /// separuh viewport. Di situ ia dimulai dalam keadaan terlipat.
  static bool shouldCollapseSummary(Size viewport) => viewport.height < 700;
}
