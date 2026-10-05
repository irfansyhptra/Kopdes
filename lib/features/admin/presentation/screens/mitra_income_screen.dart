import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/kopdes_console.dart';

/// Uang masuk dari barang mitra UMKM yang laku.
///
/// Satu-satunya jendela pengurus ke penjualan mitra. Pesanannya sendiri
/// bukan urusan koperasi: pembeli, alamat, dan isi keranjang tidak ada di
/// sini, dan memang tidak dikirim server.
class MitraIncomeScreen extends ConsumerWidget {
  const MitraIncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mitraIncomeProvider);
    final notifier = ref.read(mitraIncomeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Uang Masuk dari Mitra',
            subtitle: 'Fee penjualan barang mitra UMKM',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/admin'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: notifier.load,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 400) notifier.loadMore();
                  return false;
                },
                child: async.when(
                  skipLoadingOnRefresh: true,
                  loading: () => const StoreSubpageBody(
                    children: [
                      SectionSkeleton(height: 150),
                      SizedBox(height: AppSpacing.md),
                      SectionSkeleton(height: 220),
                    ],
                  ),
                  error: (e, _) => StoreSubpageBody(
                    children: [
                      SectionError(
                        message: networkErrorMessage(e),
                        onRetry: notifier.load,
                      ),
                    ],
                  ),
                  data: (page) => StoreSubpageBody(
                    children: [
                      _SummaryCard(summary: page.summary),
                      const SizedBox(height: AppSpacing.lg),
                      const StoreSectionHeader(
                        'Rincian penjualan mitra',
                        subtitle:
                            'Hanya pesanan yang sudah selesai yang dihitung.',
                      ),
                      if (page.entries.isEmpty)
                        const _Empty()
                      else ...[
                        for (final e in page.entries) ...[
                          _IncomeRow(entry: e),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (page.hasMore)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.base),
                            child: Center(
                              child: AppleActivityIndicator(size: 20),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _Note(feePercent: page.summary.feePercent),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MitraIncomeSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Cell(
                    label: 'Fee bulan ini',
                    value: formatRupiah(summary.feeThisMonth),
                    note:
                        'dari ${formatRupiah(summary.grossThisMonth)} '
                        'penjualan mitra',
                  ),
                ),
                const VerticalDivider(
                  width: AppSpacing.base,
                  thickness: 1,
                  color: AppColors.hairlineSoft,
                ),
                Expanded(
                  child: _Cell(
                    label: 'Fee seluruhnya',
                    value: formatRupiah(summary.feeAllTime),
                    note: '${summary.itemsSold} barang mitra terjual',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final String note;

  const _Cell({required this.label, required this.value, required this.note});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          fontSize: 12.5,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        note,
        style: AppTypography.captionSmall.copyWith(
          fontSize: 12,
          color: AppColors.muted,
        ),
      ),
    ],
  );
}

class _IncomeRow extends StatelessWidget {
  final MitraIncomeEntry entry;
  const _IncomeRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final name = entry.variantName == null
        ? entry.productName
        : '${entry.productName} (${entry.variantName})';

    return StoreSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(Icons.storefront_rounded, tint: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${entry.umkmName} · ${entry.quantity} barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  shortDateId(entry.soldAt),
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Nominal diletakkan di bawah keterangannya, bukan di
                // sampingnya: pada skala teks 2× keduanya tidak muat sebaris
                // di layar 320 dp, dan mengecilkan angka uang bukan pilihan.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '+${formatRupiah(entry.fee)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.successText,
                      ),
                    ),
                    Text(
                      'dari ${formatRupiah(entry.gross)}',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final int feePercent;
  const _Note({required this.feePercent});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Koperasi menerima fee $feePercent% dari tiap penjualan mitra. '
          'Isi pesanan mitra — pembeli dan alamatnya — adalah urusan mitra '
          'dengan pembelinya, jadi tidak ditampilkan di sini.',
          style: AppTypography.captionSmall.copyWith(
            fontSize: 12.5,
            color: AppColors.muted,
          ),
        ),
      ),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 34,
          color: AppColors.mutedSoft,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Belum ada penjualan mitra yang selesai',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Fee tercatat setelah pembeli menerima barangnya.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
