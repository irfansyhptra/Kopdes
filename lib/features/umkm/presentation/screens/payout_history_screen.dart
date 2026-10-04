import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/payout_repository.dart';
import '../widgets/seller_page_ui.dart';
import '../widgets/store_page_ui.dart';

/// Status pencairan: ikon + kata, warna hanya penegas.
StatusPill payoutStatusPill(PayoutStatus s) => switch (s) {
  PayoutStatus.requested => const StatusPill(
    icon: Icons.hourglass_top_rounded,
    label: 'Diproses',
    tint: AppColors.warning,
    text: AppColors.warningText,
  ),
  PayoutStatus.paid => const StatusPill(
    icon: Icons.check_circle_rounded,
    label: 'Sudah ditransfer',
    tint: AppColors.success,
    text: AppColors.successText,
  ),
  PayoutStatus.rejected => const StatusPill(
    icon: Icons.cancel_outlined,
    label: 'Ditolak',
    tint: AppColors.error,
    text: AppColors.errorText,
  ),
};

/// Riwayat pencairan penjual.
class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  static const _key = (admin: false, status: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(payoutListProvider(_key));
    final notifier = ref.read(payoutListProvider(_key).notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Riwayat Pencairan',
            subtitle: 'Pengajuan dan transfer saldo toko',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(payoutSummaryProvider);
                await notifier.load();
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 400) notifier.loadMore();
                  return false;
                },
                child: async.when(
                  loading: () => const StoreSubpageBody(
                    children: [
                      SectionSkeleton(height: 96),
                      SizedBox(height: AppSpacing.md),
                      SectionSkeleton(height: 96),
                    ],
                  ),
                  error: (e, _) => StoreSubpageBody(
                    children: [
                      SectionError(
                        message: networkErrorMessage(e),
                        onRetry: notifier.retry,
                      ),
                    ],
                  ),
                  data: (state) => state.items.isEmpty
                      ? const StoreSubpageBody(children: [_Empty()])
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.base,
                            AppSpacing.md,
                            AppSpacing.base,
                            AppSpacing.xl +
                                MediaQuery.paddingOf(context).bottom,
                          ),
                          itemCount:
                              state.items.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) => i == state.items.length
                              ? const Center(
                                  child: AppleActivityIndicator(size: 22),
                                )
                              : Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: storePageMaxWidth,
                                    ),
                                    child: PayoutCard(payout: state.items[i]),
                                  ),
                                ),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Column(
      children: [
        const Icon(Icons.receipt_long_outlined, color: AppColors.muted),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Belum ada pencairan.',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        Text(
          'Pengajuan "Tarik saldo" Anda akan muncul di sini beserta statusnya.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13.5,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

/// Satu pencairan. Dipakai juga di antrean admin (dengan [trailing]).
class PayoutCard extends StatelessWidget {
  final Payout payout;
  final Widget? trailing;
  final bool showStore;

  const PayoutCard({
    super.key,
    required this.payout,
    this.trailing,
    this.showStore = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = payout;
    final caption = AppTypography.captionSmall.copyWith(
      fontSize: 12.5,
      color: AppColors.muted,
    );
    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                formatRupiah(p.amount),
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              payoutStatusPill(p.status),
            ],
          ),
          if (showStore && p.umkmName != null) ...[
            const SizedBox(height: 4),
            Text(
              p.umkmName!,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
          const SizedBox(height: 4),
          SelectableText(
            '${p.bankName} ${p.accountNumber} · a.n. ${p.accountHolder}',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 2),
          Text('Diajukan ${dateTimeId(p.requestedAt)}', style: caption),
          if (p.status == PayoutStatus.paid && p.transferRef != null)
            Text(
              'Ditransfer ${p.processedAt == null ? '' : dateTimeId(p.processedAt!)}'
              ' · Ref. ${p.transferRef}',
              style: caption,
            ),
          if (p.status == PayoutStatus.rejected && p.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Alasan: ${p.rejectionReason}. Nominal kembali ke saldo tersedia.',
                style: caption.copyWith(color: AppColors.errorText),
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
