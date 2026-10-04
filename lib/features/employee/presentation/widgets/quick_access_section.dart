import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Delapan pintu masuk pekerjaan harian pegawai.
///
/// Tile yang tidak boleh dipakai tidak dihilangkan diam-diam melainkan
/// ditandai terkunci: pegawai perlu tahu fiturnya ada dan siapa yang bisa
/// membukanya. Penolakan sesungguhnya tetap di backend.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key, required this.columns});

  final int columns;

  static const _actions = <_QuickAction>[
    _QuickAction(
      label: 'Input Barang',
      icon: Icons.add_box_rounded,
      color: KopdesEmployeeColors.primary,
      route: '/pegawai/barang/baru',
      permission: Permissions.productCreate,
    ),
    _QuickAction(
      label: 'Pesanan Masuk',
      icon: Icons.receipt_long_rounded,
      color: KopdesEmployeeColors.info,
      route: '/pegawai/pesanan',
      permission: Permissions.orderRead,
    ),
    _QuickAction(
      label: 'Atur Pengiriman',
      icon: Icons.route_rounded,
      color: KopdesEmployeeColors.purple,
      route: '/pegawai/pengiriman',
      permission: Permissions.deliveryRead,
    ),
    _QuickAction(
      label: 'Kirim ke Kurir',
      icon: Icons.two_wheeler_rounded,
      color: KopdesEmployeeColors.success,
      route: '/pegawai/kurir',
      permission: Permissions.deliveryAssign,
    ),
    _QuickAction(
      label: 'Lacak Pesanan',
      icon: Icons.my_location_rounded,
      color: Color(0xFF0E9AA7),
      route: '/pegawai/lacak',
      permission: Permissions.deliveryRead,
    ),
    _QuickAction(
      label: 'Manajemen Stok',
      icon: Icons.inventory_2_rounded,
      color: KopdesEmployeeColors.warning,
      route: '/pegawai/stok',
      permission: Permissions.inventoryRead,
    ),
    _QuickAction(
      label: 'Keuangan',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF2F6D3C),
      route: '/pegawai/keuangan',
      permission: Permissions.financeReadSummary,
    ),
    _QuickAction(
      label: 'AI Assistant',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFB3208C),
      route: '/pegawai/ai',
      permission: Permissions.aiAssist,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KopdesSectionHeader(title: 'Akses Cepat'),
        const SizedBox(height: KopdesSpacing.md),
        AppleResponsiveGrid(
          minimumItemWidth: 64,
          maxColumns: columns,
          spacing: KopdesSpacing.sm,
          runSpacing: KopdesSpacing.sm,
          itemExtentBuilder: (context, _) {
            final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
            return 86 + 38 * (scale.clamp(1.0, 2.0) - 1);
          },
          children: [for (final action in _actions) _QuickTile(action: action)],
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    required this.permission,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String permission;
}

class _QuickTile extends ConsumerWidget {
  const _QuickTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(hasPermissionProvider(action.permission));

    return Semantics(
      button: true,
      enabled: allowed,
      label: allowed
          ? action.label
          : '${action.label}, tidak tersedia untuk peran Anda',
      child: Opacity(
        opacity: allowed ? 1 : 0.45,
        child: InkWell(
          onTap: allowed
              ? () => context.push(action.route)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${action.label} tidak termasuk wewenang Anda. '
                      'Hubungi Admin Kopdes.',
                    ),
                  ),
                ),
          borderRadius: BorderRadius.circular(KopdesRadii.tile),
          child: Container(
            // Tinggi tetap supaya baris tile tidak bergerigi saat satu label
            // memakai dua baris dan tetangganya satu baris.
            constraints: const BoxConstraints(minHeight: 86),
            padding: const EdgeInsets.symmetric(
              vertical: KopdesSpacing.md,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              color: KopdesEmployeeColors.tint(action.color),
              borderRadius: BorderRadius.circular(KopdesRadii.tile),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(action.icon, size: 24, color: action.color),
                    if (!allowed)
                      const Positioned(
                        right: -6,
                        bottom: -4,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: KopdesEmployeeColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: KopdesSpacing.sm),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: KopdesEmployeeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
