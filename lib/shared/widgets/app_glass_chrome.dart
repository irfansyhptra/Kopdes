import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';
import 'apple_ui.dart';

/// Kerangka kaca yang dipakai bersama seluruh peran.
///
/// Sebelumnya tiap peran punya kerangkanya sendiri: pelanggan memakai bilah
/// kaca mengambang, pegawai memakai bilah putih pekat bergaris atas dengan
/// palet terpisah. Dua bahasa untuk satu benda yang sama membuat "bilah bawah"
/// berarti dua hal berbeda tergantung siapa yang masuk.
///
/// Sekarang satu berkas ini yang memegang bentuknya — tinggi, radius, kaca,
/// dan pil merah pada tab aktif — dan tiap peran hanya menyodorkan daftar
/// tujuannya.

// ─────────────────────────────────────────────────────────────
// Bilah bawah
// ─────────────────────────────────────────────────────────────

class GlassNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Tombol aksi yang selalu berisi, bukan tab yang bisa aktif — misalnya
  /// "Tambah" pada bilah pegawai atau "Asisten" pada bilah pelanggan.
  final bool accent;

  const GlassNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.accent = false,
  });
}

/// Bilah bawah kaca yang mengambang di atas isi.
///
/// Ini salah satu dari sedikit tempat kaca dipakai: bilahnya benar-benar
/// melayang di atas konten yang menggulir, jadi translusensi menyampaikan
/// lapisan — bukan sekadar hiasan. Isinya tetap solid dan kontras penuh.
class AppGlassNavBar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const AppGlassNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelect,
  });

  /// Tinggi bar itu sendiri, tanpa jarak amannya.
  static const double barHeight = 76;

  /// Tinggi total yang ditempati bar, termasuk jarak bawahnya.
  ///
  /// Halaman yang menaruh panel mengambang sendiri di atas bar ini memakai
  /// nilai ini alih-alih menebak angka padding yang akan salah begitu tinggi
  /// bar berubah.
  static double totalHeight(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return barHeight + (safeBottom > 0 ? safeBottom : AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        safeBottom > 0 ? safeBottom : AppSpacing.md,
      ),
      child: GlassSurface(
        radius: AppleRadii.floating,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _GlassNavButton(
                    item: items[i],
                    selected: i == activeIndex,
                    onTap: () {
                      if (i == activeIndex && !items[i].accent) return;
                      HapticFeedback.selectionClick();
                      onSelect(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GlassNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduce ? Duration.zero : AppAnimation.fast;
    final filled = item.accent || selected;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Seluruh kolom ≥44px, jadi target sentuh aman walau ikonnya kecil.
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kapsul terisi penuh saat aktif. Isian tipis membuat tab aktif
              // nyaris tidak terbaca sekilas, dan penandanya jatuh ke warna
              // teks saja.
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: item.accent ? 40 : 38,
                height: item.accent ? 40 : 26,
                decoration: BoxDecoration(
                  color: filled ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  filled ? item.activeIcon : item.icon,
                  size: 20,
                  color: filled ? AppColors.onPrimary : AppColors.muted,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOut,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  // Tab aktif ditandai warna DAN bobot, bukan warna saja.
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kepala halaman
// ─────────────────────────────────────────────────────────────

/// Tombol ikon di kepala halaman — kaca, dengan lencana opsional.
///
/// Bentuk yang sama dipakai di atas kepala merah maupun di atas kanvas terang,
/// jadi warnanya diturunkan dari [onDark] alih-alih ditulis ulang di tiap
/// pemanggil.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int badge;
  final bool onDark;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.badge = 0,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.onPrimary : AppColors.ink;

    return ApplePressable(
      onTap: onTap,
      semanticLabel: badge > 0 ? '$label, $badge baru' : label,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onDark
                  ? const Color(0x26FFFFFF)
                  : AppColors.canvas.withValues(alpha: 0.72),
              border: Border.all(
                color: onDark ? const Color(0x33FFFFFF) : AppColors.hairline,
                width: 1,
              ),
              boxShadow: onDark ? null : AppElevation.subtle,
            ),
            child: Icon(icon, size: 20, color: foreground),
          ),
          // Nol berarti lencana tidak digambar, bukan bulatan berisi "0".
          if (badge > 0)
            Positioned(
              top: 2,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: AppTypography.captionSmall.copyWith(
                    // 11px: batas bawah keterbacaan menurut HIG.
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kepala halaman bertema merah dengan tombol kaca di kanannya.
///
/// Dipakai oleh halaman utama tiap peran: judul di kiri, aksi di kanan, isi
/// tambahan di bawahnya. Bentuknya satu — yang berbeda hanya isinya.
class GlassPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? child;

  const GlassPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkRed, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 13,
                              color: const Color(0xE6FFFFFF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: AppSpacing.sm),
                    action,
                  ],
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: AppSpacing.base),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
