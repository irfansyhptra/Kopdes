import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import 'apple_ui.dart';

/// Tab bar mengambang dengan material liquid glass.
///
/// Ini salah satu dari dua tempat glass dipakai di aplikasi: bar ini benar-benar
/// melayang di atas konten yang menggulir, jadi translusensi menyampaikan
/// lapisan — bukan sekadar dekorasi. Isi bar tetap solid & kontras penuh.
class CustomBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.navigationShell,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem('Beranda', Icons.house_rounded, Icons.house_outlined),
    _NavItem(
      'Marketplace',
      Icons.storefront_rounded,
      Icons.storefront_outlined,
    ),
    _NavItem(
      'Asisten',
      Icons.auto_awesome,
      Icons.auto_awesome_outlined,
      isAccent: true,
    ),
    _NavItem('Pesanan', Icons.inventory_2_rounded, Icons.inventory_2_outlined),
    _NavItem('Profil', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  /// Tinggi bar itu sendiri, tanpa jarak amannya.
  static const double barHeight = 70;

  /// Tinggi total yang ditempati bar, termasuk jarak bawahnya.
  ///
  /// Halaman yang menaruh panel mengambang sendiri di atas bar ini — misalnya
  /// Ringkasan Belanja — memakai nilai ini alih-alih menebak angka padding
  /// yang akan salah begitu tinggi bar berubah.
  static double totalHeight(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return barHeight + (safeBottom > 0 ? safeBottom : AppSpacing.md);
  }

  void _select(int index) {
    if (index == navigationShell.currentIndex) return;
    HapticFeedback.selectionClick();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = navigationShell.currentIndex;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        safeBottom > 0 ? safeBottom : AppSpacing.md,
      ),
      child: GlassSurface(
        radius: 24,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: _items[i],
                  selected: i == activeIndex,
                  onTap: () => _select(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduce ? Duration.zero : AppAnimation.fast;

    // Aksen tetap ada untuk Asisten AI, tapi hanya lewat isian solid pada
    // indikator terpilih — bukan gradien + glow di setiap keadaan.
    final Color fg = selected ? AppColors.primary : AppColors.muted;

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
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: item.isAccent ? 40 : 44,
                height: item.isAccent ? 40 : 30,
                decoration: BoxDecoration(
                  color: item.isAccent
                      ? AppColors.primary
                      : (selected
                            ? AppColors.primaryFaint
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(
                    item.isAccent ? AppRadius.pill : AppRadius.sm + 2,
                  ),
                ),
                child: Icon(
                  selected || item.isAccent ? item.active : item.inactive,
                  size: 21,
                  color: item.isAccent ? AppColors.onPrimary : fg,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOut,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  // Lokasi aktif ditandai warna DAN bobot, bukan warna saja.
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

class _NavItem {
  final String label;
  final IconData active;
  final IconData inactive;
  final bool isAccent;

  const _NavItem(
    this.label,
    this.active,
    this.inactive, {
    this.isAccent = false,
  });
}
