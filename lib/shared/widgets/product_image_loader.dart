import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Menampilkan gambar produk dengan placeholder & error handling seragam.
///
/// Dua hal yang menentukan kelancaran scroll di sini:
/// 1. **Decode seukuran tampilan.** Tanpa `cacheWidth`, foto 1000px di-decode
///    penuh ke RAM walau hanya digambar di kotak 170px — ±16× memori dan waktu
///    decode yang sia-sia per kartu.
/// 2. **Placeholder statis.** Spinner yang beranimasi memaksa satu frame ulang
///    per gambar per 16ms; di grid berisi 20 kartu itu 20 animasi berjalan
///    sekaligus saat pengguna menggulir.
class ProductImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double placeholderIconSize;

  const ProductImageLoader({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _wrap(_placeholder());

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;

    return _wrap(
      LayoutBuilder(
        builder: (context, constraints) {
          // Batas atas decode: lebar slot × kerapatan piksel layar. Dibatasi
          // 1080 supaya foto raksasa tidak lolos lewat constraint tak terbatas.
          final target = constraints.hasBoundedWidth
              ? (constraints.maxWidth * dpr).round().clamp(64, 1080)
              : (width != null ? (width! * dpr).round().clamp(64, 1080) : 720);

          return Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: target,
            // Pertahankan frame lama saat URL berubah — tidak berkedip putih.
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _placeholder(),
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              // Fade masuk sekali di atas latar netral, bukan animasi berjalan.
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppAnimation.normal,
                curve: Curves.easeOut,
                child: child,
              );
            },
          );
        },
      ),
    );
  }

  /// Latar netral selalu ada di bawah gambar, jadi slot tidak pernah kosong
  /// putih saat gambar belum sampai — tanpa widget skeleton terpisah.
  Widget _wrap(Widget child) {
    final base = ColoredBox(color: AppColors.surfaceSoft, child: child);
    return borderRadius == null
        ? base
        : ClipRRect(borderRadius: borderRadius!, child: base);
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.surfaceSoft,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: placeholderIconSize,
        color: AppColors.mutedSoft,
      ),
    ),
  );
}
