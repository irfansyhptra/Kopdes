import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/content_page.dart';

/// Ajakan menjadi anggota Koperasi Desa Merah Putih.
///
/// Sengaja **tidak** memuat angka: tidak ada nominal simpanan, persentase SHU,
/// maupun janji imbal hasil. Hal-hal itu diatur AD/ART koperasi, dan
/// menampilkannya di banner promosi tanpa dasar resmi akan membuatnya terbaca
/// sebagai tawaran investasi.
///
/// "Pelajari Manfaat" sengaja diletakkan berdampingan dengan "Daftar Sekarang"
/// agar membaca ketentuan bukan langkah yang harus dicari-cari lebih dulu.
class MembershipBanner extends StatelessWidget {
  const MembershipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.darkRed, AppColors.brightRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppleRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.yellowAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Jadi Anggota Koperasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Tumbuh Bersama, Sejahtera Bersama',
                        style: TextStyle(
                          color: AppColors.yellowAccent.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Daftar sebagai anggota dan ikut berpartisipasi dalam '
              'perkembangan koperasi desa Anda.',
              style: TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _BannerButton(
                    label: 'Daftar Sekarang',
                    filled: true,
                    onTap: () => context.push('/membership/register'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _BannerButton(
                    label: 'Pelajari Manfaat',
                    onTap: () =>
                        context.push('/info/${ContentSlugs.manfaatAnggota}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _BannerButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: label,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleRadii.control),
          border: Border.all(
            color: filled ? AppColors.canvas : const Color(0x66FFFFFF),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: filled ? AppColors.primary : Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
