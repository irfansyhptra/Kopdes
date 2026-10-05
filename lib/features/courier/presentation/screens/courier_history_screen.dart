import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_models.dart';
import '../../data/courier_repository.dart';
import '../widgets/courier_ui.dart';
import 'courier_tasks_screen.dart' show CourierEmptyState;

/// Log pengiriman: tugas yang sudah selesai, terbaru dulu, berhalaman.
class CourierHistoryScreen extends ConsumerWidget {
  const CourierHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courierHistoryProvider);
    final notifier = ref.read(courierHistoryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SellerPageChrome(
        title: 'Log Pengiriman',
        subtitle: 'Antaran yang sudah Anda selesaikan',
        body: RefreshIndicator(
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
                  SectionSkeleton(height: 120),
                  SizedBox(height: AppSpacing.md),
                  SectionSkeleton(height: 120),
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
              data: (page) => page.items.isEmpty
                  ? const StoreSubpageBody(
                      children: [
                        CourierEmptyState(
                          icon: Icons.history_rounded,
                          title: 'Belum ada antaran selesai',
                          body:
                              'Setiap pesanan yang Anda tandai sudah diantar '
                              'tercatat di sini.',
                        ),
                      ],
                    )
                  : StoreSubpageBody(
                      children: [
                        for (final task in page.items) ...[
                          _HistoryRow(task: task),
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
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final CourierTask task;
  const _HistoryRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final at = task.confirmedAt ?? task.deliveredAt;
    return ApplePressable(
      onTap: () => context.push('/courier/tugas/${task.id}'),
      pressedScale: 0.99,
      child: StoreSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(task.stage.icon, tint: task.stage.tint),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${task.shortCode} · ${task.destination.recipientName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    task.destination.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      taskStagePill(task.stage),
                      if (at != null)
                        Text(
                          dateTimeId(at),
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
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
