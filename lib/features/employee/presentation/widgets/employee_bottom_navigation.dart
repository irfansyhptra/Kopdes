import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_glass_chrome.dart';

/// Tujuan navigasi bawah khusus Pegawai Kopdes.
///
/// Sengaja tidak memakai menu pelanggan (Marketplace, Keranjang): pegawai
/// membuka aplikasi untuk bekerja, dan tab belanja di sana hanya menambah
/// jalur salah tekan saat sedang melayani antrean.
///
/// Bentuk bilahnya sendiri datang dari [AppGlassNavBar], sama persis dengan
/// bilah pelanggan — yang berbeda hanya daftar tujuannya.
enum EmployeeNavItem { home, orders, add, stock, profile }

class EmployeeBottomNavigation extends StatelessWidget {
  const EmployeeBottomNavigation({super.key, required this.activeItem});

  final EmployeeNavItem activeItem;

  static const _routes = {
    EmployeeNavItem.home: '/pegawai',
    EmployeeNavItem.orders: '/pegawai/pesanan',
    EmployeeNavItem.add: '/pegawai/barang/baru',
    EmployeeNavItem.stock: '/pegawai/stok',
    EmployeeNavItem.profile: '/pegawai/profil',
  };

  static const List<GlassNavItem> _items = [
    GlassNavItem(
      label: 'Beranda',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    GlassNavItem(
      label: 'Pesanan',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
    // Tambah barang adalah tindakan, bukan tab: ia tidak pernah "sedang
    // dibuka", jadi ia selalu berisi seperti Asisten di bilah pelanggan.
    GlassNavItem(
      label: 'Tambah',
      icon: Icons.add_rounded,
      activeIcon: Icons.add_rounded,
      accent: true,
    ),
    GlassNavItem(
      label: 'Stok',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
    ),
    GlassNavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final values = EmployeeNavItem.values;

    return AppGlassNavBar(
      items: _items,
      activeIndex: values.indexOf(activeItem),
      onSelect: (index) {
        final target = _routes[values[index]]!;
        // "Tambah" ditumpuk supaya pegawai kembali ke layar tempat ia menekan,
        // bukan ke beranda; tab lain berpindah, tidak menumpuk.
        if (values[index] == EmployeeNavItem.add) {
          context.push(target);
        } else {
          context.go(target);
        }
      },
    );
  }
}
