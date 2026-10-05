import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/cancellation_repository.dart';
import '../../domain/entities/order.dart';

/// Pesanan Dibatalkan — satu halaman untuk tiga keadaan sekaligus:
/// pengajuan yang menunggu, yang ditolak toko, dan yang benar-benar batal.
///
/// Dipisah jadi tiga daftar hanya memaksa orang menebak harus membuka yang
/// mana; di sini urutannya terbaru dulu dan tiap kartu menyebut keadaannya.
class CancellationsScreen extends ConsumerWidget {
  const CancellationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cancellationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Pesanan Dibatalkan',
            subtitle: 'Pengajuan, penolakan, dan pembatalan',
            onBack: () => context.canPop()
                ? context.pop()
                : context.go('/orders/history'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(cancellationsProvider);
                try {
                  await ref.read(cancellationsProvider.future);
                } catch (_) {}
              },
              child: async.when(
                skipLoadingOnRefresh: true,
                loading: () => const StoreSubpageBody(
                  children: [
                    SectionSkeleton(height: 140),
                    SizedBox(height: AppSpacing.md),
                    SectionSkeleton(height: 140),
                  ],
                ),
                error: (e, _) => StoreSubpageBody(
                  children: [
                    SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () => ref.invalidate(cancellationsProvider),
                    ),
                  ],
                ),
                data: (list) => list.isEmpty
                    ? const StoreSubpageBody(children: [_Empty()])
                    : StoreSubpageBody(
                        children: [
                          for (final o in list) ...[
                            _CancelCard(order: o),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

StatusPill cancellationPill(CancellationState s) => switch (s) {
  CancellationState.requested => const StatusPill(
    icon: Icons.hourglass_top_rounded,
    label: 'Menunggu jawaban toko',
    tint: AppColors.warning,
    text: AppColors.warningText,
  ),
  CancellationState.rejected => const StatusPill(
    icon: Icons.block_rounded,
    label: 'Pengajuan ditolak',
    tint: AppColors.error,
    text: AppColors.errorText,
  ),
  CancellationState.approved => const StatusPill(
    icon: Icons.cancel_outlined,
    label: 'Pesanan dibatalkan',
    tint: AppColors.muted,
    text: AppColors.body,
  ),
  CancellationState.none => const StatusPill(
    icon: Icons.cancel_outlined,
    label: 'Dibatalkan toko',
    tint: AppColors.muted,
    text: AppColors.body,
  ),
};

class _CancelCard extends StatelessWidget {
  final CancelledOrder order;
  const _CancelCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final names = order.items.map((i) => '${i.quantity}× ${i.name}').join(', ');

    return ApplePressable(
      onTap: () => context.push('/orders/${order.id}'),
      pressedScale: 0.99,
      child: StoreSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '#${order.shortCode}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  shortDateId(order.createdAt),
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: cancellationPill(order.cancellation),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              names.isEmpty ? '${order.totalQuantity} barang' : names,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.body,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(order.totalAmount),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (order.reason != null && order.reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _Line(label: 'Alasan Anda', value: order.reason!),
            ],
            if (order.cancellation == CancellationState.rejected &&
                (order.rejectReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: AppSpacing.sm),
              _Line(
                label: 'Jawaban toko',
                value: order.rejectReason!,
                tint: AppColors.errorText,
              ),
            ],
            if (order.cancellation == CancellationState.requested) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pesanan ini masih berjalan sampai toko menjawab.',
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color? tint;

  const _Line({required this.label, required this.value, this.tint});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          fontSize: 12,
          color: AppColors.muted,
        ),
      ),
      Text(
        value,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 13.5,
          color: tint ?? AppColors.body,
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
        const Icon(Icons.inbox_rounded, size: 34, color: AppColors.mutedSoft),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Belum ada pesanan yang dibatalkan',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pengajuan pembatalan dan hasilnya akan tercatat di halaman ini.',
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
