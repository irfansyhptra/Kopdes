import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_glass_chrome.dart';

/// Bilah bawah pelanggan.
///
/// Bentuknya datang dari [AppGlassNavBar] — sama persis dengan bilah pegawai.
/// Yang tinggal di sini hanya daftar tujuan pelanggan dan cara berpindahnya
/// lewat `StatefulNavigationShell`.
class CustomBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.navigationShell,
    required this.onTap,
  });

  static const List<GlassNavItem> _items = [
    GlassNavItem(
      label: 'Beranda',
      icon: Icons.house_outlined,
      activeIcon: Icons.house_rounded,
    ),
    GlassNavItem(
      label: 'Marketplace',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    GlassNavItem(
      label: 'Asisten',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      accent: true,
    ),
    GlassNavItem(
      label: 'Pesanan',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
    ),
    GlassNavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  /// Tinggi bar itu sendiri, tanpa jarak amannya.
  static const double barHeight = AppGlassNavBar.barHeight;

  /// Tinggi total yang ditempati bar, termasuk jarak bawahnya.
  static double totalHeight(BuildContext context) =>
      AppGlassNavBar.totalHeight(context);

  @override
  Widget build(BuildContext context) {
    return AppGlassNavBar(
      items: _items,
      activeIndex: navigationShell.currentIndex,
      onSelect: onTap,
    );
  }
}
