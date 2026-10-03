import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/employee_dashboard.dart';
import '../../domain/employee_responsive.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Kartu stok dan keuangan.
///
/// Berdampingan bila lebarnya cukup, bertumpuk pada layar sempit — dua kolom
/// di 320 dp menyisakan sekitar 140 dp per kartu, terlalu sempit untuk
/// "Rp3.450.000" berdampingan dengan grafiknya.
class DashboardInsightPanels extends StatelessWidget {
  const DashboardInsightPanels({super.key, required this.spec});

  final KopdesResponsiveSpec spec;

  @override
  Widget build(BuildContext context) {
    if (!spec.sideBySideInsights) {
      return const Column(
        children: [
          StockSummaryCard(),
          SizedBox(height: KopdesSpacing.md),
          TodayFinanceCard(),
        ],
      );
    }

    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: StockSummaryCard()),
          SizedBox(width: KopdesSpacing.md),
          Expanded(child: TodayFinanceCard()),
        ],
      ),
    );
  }
}

// ── Stok ──────────────────────────────────────────────────────────────────

class StockSummaryCard extends ConsumerWidget {
  const StockSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockSummaryProvider);

    return stock.when(
      loading: () => const KopdesSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KopdesSkeleton(height: 15, width: 110),
            SizedBox(height: KopdesSpacing.md),
            Row(
              children: [
                KopdesSkeleton(height: 64, width: 64, radius: 32),
                SizedBox(width: KopdesSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KopdesSkeleton(height: 12, width: 90),
                      SizedBox(height: 6),
                      KopdesSkeleton(height: 12, width: 80),
                      SizedBox(height: 6),
                      KopdesSkeleton(height: 12, width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      error: (_, _) => KopdesSectionError(
        message: 'Ringkasan stok belum berhasil dimuat',
        onRetry: () => ref.invalidate(stockSummaryProvider),
      ),
      data: (data) => KopdesSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ringkasan Stok',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KopdesEmployeeColors.textPrimary,
              ),
            ),
            const SizedBox(height: KopdesSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StockRing(summary: data),
                const SizedBox(width: KopdesSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StockLine(
                        color: KopdesEmployeeColors.success,
                        value: data.activeProducts,
                        label: 'Produk Aktif',
                      ),
                      _StockLine(
                        color: KopdesEmployeeColors.warning,
                        value: data.lowStock,
                        label: 'Stok Menipis',
                      ),
                      _StockLine(
                        color: KopdesEmployeeColors.primary,
                        value: data.outOfStock,
                        label: 'Habis',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.allHealthy) ...[
              const SizedBox(height: KopdesSpacing.sm),
              const Text(
                'Semua stok dalam kondisi aman',
                style: TextStyle(
                  fontSize: 12,
                  color: KopdesEmployeeColors.success,
                ),
              ),
            ],
            const SizedBox(height: KopdesSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/pegawai/stok'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Kelola Stok',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KopdesEmployeeColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cincin proporsi stok — `CustomPaint` statis, tanpa animation controller.
///
/// Grafiknya kecil dan hanya menunjukkan perbandingan tiga angka; menganimasi
/// ulang cincin ini setiap kali dashboard menyegarkan diri akan menyalakan
/// raster tiap 45 detik tanpa memberi informasi baru apa pun.
class _StockRing extends StatelessWidget {
  const _StockRing({required this.summary});

  final StockSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _RingPainter(
          segments: [
            (summary.healthy.toDouble(), KopdesEmployeeColors.success),
            (summary.lowStock.toDouble(), KopdesEmployeeColors.warning),
            (summary.outOfStock.toDouble(), KopdesEmployeeColors.primary),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${summary.activeProducts}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: KopdesEmployeeColors.textPrimary,
                ),
              ),
              const Text(
                'produk',
                style: TextStyle(
                  fontSize: 9,
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

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.segments});

  final List<(double, Color)> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.$1);
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.butt;

    // Katalog kosong: satu cincin abu, bukan lingkaran yang hilang sama sekali.
    if (total <= 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        paint..color = const Color(0xFFE8E8EA),
      );
      return;
    }

    var start = -math.pi / 2;
    for (final (value, color) in segments) {
      if (value <= 0) continue;
      final sweep = (value / total) * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _StockLine extends StatelessWidget {
  const _StockLine({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          // Angka dan label disatukan dalam satu Text: dua Text bersebelahan
          // membuat angkanya tidak bisa ikut menyusut, dan pada kartu selebar
          // 158 dp itulah yang meluber.
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: KopdesEmployeeColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: label),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Keuangan ──────────────────────────────────────────────────────────────

class TodayFinanceCard extends ConsumerWidget {
  const TodayFinanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(
      hasPermissionProvider(Permissions.financeReadSummary),
    );

    // Tanpa wewenang keuangan, nominalnya tidak ditarik sama sekali — bukan
    // ditarik lalu disembunyikan, karena payload-nya tetap sampai ke perangkat.
    if (!allowed) {
      return const KopdesSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keuangan Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KopdesEmployeeColors.textPrimary,
              ),
            ),
            SizedBox(height: KopdesSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: KopdesEmployeeColors.textSecondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tidak termasuk wewenang Anda',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: KopdesEmployeeColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final finance = ref.watch(financeSummaryProvider);

    return finance.when(
      loading: () => const KopdesSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KopdesSkeleton(height: 15, width: 130),
            SizedBox(height: KopdesSpacing.md),
            KopdesSkeleton(height: 12, width: 70),
            SizedBox(height: 6),
            KopdesSkeleton(height: 24, width: 150),
            SizedBox(height: 10),
            KopdesSkeleton(height: 12, width: 110),
          ],
        ),
      ),
      error: (_, _) => KopdesSectionError(
        message: 'Rekap keuangan belum berhasil dimuat',
        onRetry: () => ref.invalidate(financeSummaryProvider),
      ),
      data: (data) => KopdesSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Keuangan Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KopdesEmployeeColors.textPrimary,
              ),
            ),
            const SizedBox(height: KopdesSpacing.md),
            const Text(
              'Penjualan',
              style: TextStyle(
                fontSize: 12,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.grossSales.formatted,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: KopdesEmployeeColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: KopdesSpacing.sm),
            Text(
              '${data.transactionCount} Transaksi',
              style: const TextStyle(
                fontSize: 12.5,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
            if (data.changePercent != null) ...[
              const SizedBox(height: 2),
              Text(
                '${data.changePercent! >= 0 ? '+' : ''}'
                '${data.changePercent}% dari kemarin',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: data.changePercent! >= 0
                      ? KopdesEmployeeColors.success
                      : KopdesEmployeeColors.primary,
                ),
              ),
            ],
            const SizedBox(height: KopdesSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/pegawai/keuangan'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Laporan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KopdesEmployeeColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
