import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Empat KPI operasional dalam satu grouped surface.
///
/// Satu permukaan dengan divider tipis, bukan empat kartu terpisah: empat
/// kartu memberi tiga celah dan empat bayangan untuk membaca empat angka,
/// dan pada 320 dp celah itulah yang memakan tempat angkanya.
class EmployeeKpiSection extends ConsumerWidget {
  const EmployeeKpiSection({super.key, required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(employeeSummaryProvider);

    return summary.when(
      loading: () => _KpiSkeleton(columns: columns),
      error: (_, _) => KopdesSectionError(
        onRetry: () => ref.invalidate(employeeSummaryProvider),
      ),
      data: (data) {
        final tiles = <_KpiData>[
          _KpiData(
            label: 'Pesanan Baru',
            value: data.newOrders,
            icon: Icons.receipt_long_rounded,
            color: KopdesEmployeeColors.primary,
            route: '/pegawai/pesanan?status=PAID',
          ),
          _KpiData(
            label: 'Perlu Diproses',
            value: data.needProcessing,
            icon: Icons.inventory_rounded,
            color: KopdesEmployeeColors.warning,
            route: '/pegawai/pesanan?status=PROCESSING',
          ),
          _KpiData(
            label: 'Siap Dikirim',
            value: data.readyToShip,
            icon: Icons.local_shipping_rounded,
            color: KopdesEmployeeColors.success,
            route: '/pegawai/pesanan?status=READY_FOR_DELIVERY',
          ),
          _KpiData(
            label: 'Stok Menipis',
            value: data.lowStockProducts,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEA6A12),
            route: '/pegawai/stok?filter=low',
          ),
        ];

        return KopdesSurface(
          padding: const EdgeInsets.symmetric(
            vertical: KopdesSpacing.md,
            horizontal: KopdesSpacing.sm,
          ),
          child: _KpiGrid(
            columns: columns,
            children: [
              for (final tile in tiles)
                _KpiTile(data: tile, onTap: () => context.push(tile.route)),
            ],
          ),
        );
      },
    );
  }
}

/// Grid dengan divider tipis di antara kolom dan baris.
///
/// `IntrinsicHeight` dipakai agar garis pemisah setinggi baris tertingginya —
/// tanpa itu, label dua baris pada skala teks besar membuat divider
/// menggantung setengah.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(
        i,
        (i + columns).clamp(0, children.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) const _VerticalDivider(),
                Expanded(child: slice[j]),
              ],
              // Baris terakhir yang tidak penuh tetap sejajar dengan baris
              // di atasnya, bukan melebar mengisi sisa ruang.
              for (var k = slice.length; k < columns; k++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + columns < children.length) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KopdesSpacing.sm),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: KopdesEmployeeColors.divider,
            ),
          ),
        );
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      child: ColoredBox(color: KopdesEmployeeColors.divider),
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String route;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.data, required this.onTap});

  final _KpiData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${data.label}: ${data.value}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KopdesRadii.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KopdesSpacing.xs,
            vertical: KopdesSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(data.icon, size: 18, color: data.color),
              const SizedBox(height: 6),
              Text(
                '${data.value}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: data.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: KopdesEmployeeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return KopdesSurface(
      padding: const EdgeInsets.symmetric(
        vertical: KopdesSpacing.md,
        horizontal: KopdesSpacing.sm,
      ),
      child: _KpiGrid(
        columns: columns,
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: KopdesSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KopdesSkeleton(height: 18, width: 18, radius: 9),
                SizedBox(height: 6),
                KopdesSkeleton(height: 20, width: 32),
                SizedBox(height: 6),
                KopdesSkeleton(height: 11, width: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
