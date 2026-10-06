import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'product_image_loader.dart';

/// Kepala kartu toko: sampul lebar dengan lencana logo di atasnya.
///
/// Kopdes menyimpan dua gambar (`logoUrl` + `imageUrl`), begitu juga mitra
/// UMKM (`photoUrl` + `bannerUrl`). Sebelum ini kartu hanya menggambar satu
/// dari keduanya, jadi logo toko tidak pernah terlihat di beranda — padahal
/// logo itulah yang dikenali warga, bukan foto bangunannya.
///
/// Logo diletakkan DI DALAM area sampul, bukan menggantung di tepinya: kartu
/// membungkusnya dengan `Column`, sehingga apa pun yang melewati batas sampul
/// akan terpotong.
class StoreCardBanner extends StatelessWidget {
  final String bannerUrl;
  final String logoUrl;
  final double height;

  /// Nama toko, dipakai hanya bila belum ada gambar sama sekali: inisialnya
  /// setidaknya menyebut toko mana, sementara ikon gambar abu-abu terbaca
  /// seperti kartu yang gagal dimuat.
  final String name;

  /// Lencana kategori atau label lain yang ditempel di pojok kiri atas.
  final Widget? topLeft;

  const StoreCardBanner({
    super.key,
    required this.bannerUrl,
    required this.logoUrl,
    required this.height,
    this.name = '',
    this.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sampul jatuh ke logo bila sampulnya belum diunggah — lebih baik
          // menampilkan gambar yang ada daripada kotak placeholder.
          if (bannerUrl.isNotEmpty || logoUrl.isNotEmpty)
            ProductImageLoader(
              imageUrl: bannerUrl.isNotEmpty ? bannerUrl : logoUrl,
              placeholderIconSize: 24,
            )
          else
            _InitialFallback(name: name),
          if (topLeft != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: topLeft!,
            ),
          // Logo hanya ditumpuk bila ia memang gambar yang berbeda dari
          // sampulnya; kalau sama, menumpuknya hanya menggandakan foto.
          if (logoUrl.isNotEmpty &&
              bannerUrl.isNotEmpty &&
              logoUrl != bannerUrl)
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              child: _LogoBadge(url: logoUrl),
            ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final String url;

  const _LogoBadge({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.canvas, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        child: ProductImageLoader(imageUrl: url, placeholderIconSize: 14),
      ),
    );
  }
}

/// Latar bertekstur lembut dengan inisial toko, untuk toko yang belum
/// mengunggah logo maupun sampul.
class _InitialFallback extends StatelessWidget {
  final String name;

  const _InitialFallback({required this.name});

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_initials.isEmpty) {
      return const ColoredBox(
        color: AppColors.surfaceSoft,
        child: Center(
          child: Icon(
            Icons.storefront_outlined,
            size: 26,
            color: AppColors.mutedSoft,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceStrong, AppColors.surfaceSoft],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedSoft,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
