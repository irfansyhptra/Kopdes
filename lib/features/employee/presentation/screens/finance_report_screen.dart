import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Laporan keuangan Kopdes: rekap harian, mingguan, dan bulanan.
///
/// Seluruh penjumlahan dikerjakan backend. Menarik daftar transaksi lalu
/// menjumlahkannya di perangkat akan salah begitu datanya melewati satu
/// halaman, dan tetap memakai kuota pengguna untuk baris yang dibuang.
class FinanceReportScreen extends ConsumerWidget {
  const FinanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(
      hasPermissionProvider(Permissions.financeReadSummary),
    );

    return Scaffold(
      backgroundColor: KopdesEmployeeColors.background,
      appBar: AppBar(
        backgroundColor: KopdesEmployeeColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: allowed ? const _Report() : const _NoAccess(),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(KopdesSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 32,
              color: KopdesEmployeeColors.textSecondary,
            ),
            SizedBox(height: KopdesSpacing.md),
            Text(
              'Laporan keuangan tidak termasuk wewenang Anda.\n'
              'Hubungi Admin Kopdes bila memerlukan akses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KopdesEmployeeColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Report extends ConsumerWidget {
  const _Report();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(financePeriodProvider);
    final finance = ref.watch(financeSummaryProvider);
    final canSeeFull = ref.watch(
      hasPermissionProvider(Permissions.financeReadFull),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(KopdesSpacing.md),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'today', label: Text('Harian')),
              ButtonSegment(value: 'week', label: Text('Mingguan')),
              ButtonSegment(value: 'month', label: Text('Bulanan')),
            ],
            selected: {period},
            onSelectionChanged: (v) =>
                ref.read(financePeriodProvider.notifier).state = v.first,
          ),
        ),
        Expanded(
          child: finance.when(
            loading: () => const _ReportSkeleton(),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(KopdesSpacing.base),
                child: KopdesSectionError(
                  message: 'Rekap keuangan belum berhasil dimuat',
                  onRetry: () => ref.invalidate(financeSummaryProvider),
                ),
              ),
            ),
            data: (data) => RefreshIndicator(
              color: KopdesEmployeeColors.primary,
              onRefresh: () async => ref.invalidate(financeSummaryProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  KopdesSpacing.md,
                  0,
                  KopdesSpacing.md,
                  KopdesSpacing.xl,
                ),
                children: [
                  KopdesSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penjualan',
                          style: TextStyle(
                            fontSize: 12.5,
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
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: KopdesSpacing.xs),
                        Text(
                          '${data.transactionCount} transaksi'
                          '${data.changePercent == null ? '' : ' • '
                                    '${data.changePercent! >= 0 ? '+' : ''}'
                                    '${data.changePercent}% dari periode sebelumnya'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: KopdesEmployeeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KopdesSpacing.md),
                  KopdesSurface(
                    child: Column(
                      children: [
                        _Line(
                          label: 'Pembayaran QRIS',
                          value: data.qrisTotal.formatted,
                        ),
                        _Line(
                          label: 'Pembayaran COD',
                          value: data.codTotal.formatted,
                        ),
                        _Line(
                          label: 'Refund',
                          value: data.refundTotal.formatted,
                          emphasis: !data.refundTotal.isZero,
                        ),
                        // Diskon dan ongkir baru tampil kalau backend memang
                        // mencatatnya. Menampilkan "Rp0" untuk sesuatu yang
                        // belum pernah dicatat terbaca sebagai fakta, padahal
                        // itu ketiadaan data.
                        if (data.discountTotal != null)
                          _Line(
                            label: 'Diskon',
                            value: data.discountTotal!.formatted,
                          ),
                        if (data.shippingTotal != null)
                          _Line(
                            label: 'Ongkir',
                            value: data.shippingTotal!.formatted,
                          ),
                      ],
                    ),
                  ),
                  if (data.discountTotal == null ||
                      data.shippingTotal == null) ...[
                    const SizedBox(height: KopdesSpacing.sm),
                    const Text(
                      'Rincian diskon dan ongkir belum dicatat terpisah pada '
                      'pesanan, sehingga belum bisa ditampilkan.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: KopdesEmployeeColors.textSecondary,
                      ),
                    ),
                  ],
                  if (!canSeeFull) ...[
                    const SizedBox(height: KopdesSpacing.md),
                    const Text(
                      'Anda melihat ringkasan. Buku besar dan laporan '
                      'rinci koperasi hanya dapat dibuka Admin Kopdes.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: KopdesEmployeeColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: emphasis
                  ? KopdesEmployeeColors.primary
                  : KopdesEmployeeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KopdesSpacing.md),
      children: const [
        KopdesSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KopdesSkeleton(height: 12, width: 70),
              SizedBox(height: 8),
              KopdesSkeleton(height: 26, width: 180),
              SizedBox(height: 8),
              KopdesSkeleton(height: 12, width: 140),
            ],
          ),
        ),
        SizedBox(height: KopdesSpacing.md),
        KopdesSurface(
          child: Column(
            children: [
              KopdesSkeleton(height: 14),
              SizedBox(height: 12),
              KopdesSkeleton(height: 14),
              SizedBox(height: 12),
              KopdesSkeleton(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
