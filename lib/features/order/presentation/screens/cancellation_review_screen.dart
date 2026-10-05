import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/reason_dialog.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/cancellation_review_repository.dart';

/// Pengajuan pembatalan dari pembeli, menunggu jawaban toko.
///
/// Dipakai pengurus Kopdes maupun penjual mitra; alamat endpoint-nya
/// mengikuti peran yang masuk.
class CancellationReviewScreen extends ConsumerWidget {
  const CancellationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingCancellationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Pengajuan Pembatalan',
            subtitle: 'Menunggu keputusan Anda',
            onBack: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(pendingCancellationsProvider);
                try {
                  await ref.read(pendingCancellationsProvider.future);
                } catch (_) {}
              },
              child: async.when(
                skipLoadingOnRefresh: true,
                loading: () => const StoreSubpageBody(
                  children: [
                    SectionSkeleton(height: 180),
                    SizedBox(height: AppSpacing.md),
                    SectionSkeleton(height: 180),
                  ],
                ),
                error: (e, _) => StoreSubpageBody(
                  children: [
                    SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () =>
                          ref.invalidate(pendingCancellationsProvider),
                    ),
                  ],
                ),
                data: (list) => list.isEmpty
                    ? const StoreSubpageBody(children: [_Empty()])
                    : StoreSubpageBody(
                        children: [
                          for (final r in list) ...[
                            _RequestCard(request: r),
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

class _RequestCard extends ConsumerWidget {
  final CancellationRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = request.items
        .map((i) => '${i.quantity}× ${i.name}')
        .join(', ');

    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '#${request.shortCode} · ${request.customerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                formatRupiah(request.totalAmount),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            names,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StoreSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alasan pembeli',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  request.reason ?? '—',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Membungkus, bukan sebaris: pada teks besar dua tombol ini tidak
          // muat berdampingan di layar sempit.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _decide(context, ref, approve: false),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 46),
                  foregroundColor: AppColors.errorText,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _decide(context, ref, approve: true),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Setujui Pembatalan'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(44, 46),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    String? reason;

    if (approve) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Setujui pembatalan?'),
          content: const Text(
            'Pesanan dibatalkan, stok dikembalikan, dan pembayaran lewat '
            'saldo dikembalikan ke pembeli. Tindakan ini tidak bisa '
            'diurungkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Setujui'),
            ),
          ],
        ),
      );
      if (yes != true || !context.mounted) return;
    } else {
      // Penolakan wajib menyebut alasan: pembeli berhak tahu sebabnya.
      reason = await askReason(
        context,
        title: 'Tolak pengajuan?',
        label: 'Alasan penolakan',
        hint: 'Mis. barang sudah dikemas',
        confirmLabel: 'Tolak',
      );
      if (reason == null || !context.mounted) return;
    }

    final alasan = reason;
    await runWithFeedback(
      context,
      waiting: approve ? 'Membatalkan pesanan…' : 'Menolak pengajuan…',
      action: () async {
        await ref
            .read(cancellationReviewServiceProvider)
            .decide(request.orderId, approve, reason: alasan);
        ref.invalidate(pendingCancellationsProvider);
        return true;
      },
      successTitle: approve ? 'Pesanan Dibatalkan' : 'Pengajuan Ditolak',
      successMessage: approve
          ? 'Stok sudah dikembalikan.'
          : 'Pembeli melihat alasan Anda di halaman pesanannya.',
    );
  }
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
          'Tidak ada pengajuan pembatalan',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pengajuan dari pembeli akan muncul di sini sebelum Anda '
          'menyiapkan pesanannya.',
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
