import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../umkm/data/payout_repository.dart';
import '../../../umkm/presentation/screens/payout_history_screen.dart'
    show PayoutCard;
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';

/// Antrean pencairan mitra UMKM untuk pengurus Kopdes.
///
/// Transfer dilakukan di luar aplikasi (mobile banking koperasi); di sini
/// pengurus mencatat hasilnya. "Sudah ditransfer" meminta nomor referensi
/// supaya penjual bisa mencocokkannya dengan mutasi rekeningnya.
/// Antrean pencairan sebagai halaman sendiri, dibuka dari tab Koperasi.
class PayoutQueuePage extends StatelessWidget {
  const PayoutQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Pencairan Mitra',
            subtitle: 'Transfer saldo penjualan mitra UMKM',
            onBack: () => context.pop(),
          ),
          const Expanded(child: PayoutQueueScreen()),
        ],
      ),
    );
  }
}

class PayoutQueueScreen extends ConsumerStatefulWidget {
  const PayoutQueueScreen({super.key});

  @override
  ConsumerState<PayoutQueueScreen> createState() => _PayoutQueueScreenState();
}

class _PayoutQueueScreenState extends ConsumerState<PayoutQueueScreen> {
  PayoutStatus? _status = PayoutStatus.requested;

  PayoutListKey get _key => (admin: true, status: _status);

  Future<String?> _ask({
    required String title,
    required String label,
    required String hint,
    required int min,
  }) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: c.text.trim().length >= min
                  ? () => Navigator.pop(context, c.text.trim())
                  : null,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(Payout p) async {
    final ref0 = await _ask(
      title: 'Sudah ditransfer ${formatRupiah(p.amount)}?',
      label: 'Nomor referensi transfer',
      hint: 'Dari bukti transfer bank',
      min: 3,
    );
    if (ref0 == null || !mounted) return;
    await runWithFeedback(
      context,
      waiting: 'Mencatat transfer…',
      action: () async {
        await ref.read(payoutRepositoryProvider).markPaid(p.id, ref0);
        return true;
      },
      successTitle: 'Transfer Tercatat',
      successMessage: '${p.umkmName ?? 'Mitra'} melihat statusnya di Riwayat.',
    );
    ref.invalidate(payoutListProvider(_key));
  }

  Future<void> _reject(Payout p) async {
    final reason = await _ask(
      title: 'Tolak pencairan?',
      label: 'Alasan',
      hint: 'Mis. nama rekening tidak sesuai',
      min: 5,
    );
    if (reason == null || !mounted) return;
    await runWithFeedback(
      context,
      waiting: 'Menolak pencairan…',
      action: () async {
        await ref.read(payoutRepositoryProvider).reject(p.id, reason);
        return true;
      },
      successTitle: 'Pencairan Ditolak',
      successMessage: 'Nominalnya kembali ke saldo tersedia mitra.',
    );
    ref.invalidate(payoutListProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(payoutListProvider(_key));
    final notifier = ref.read(payoutListProvider(_key).notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            0,
          ),
          child: SegmentedButton<PayoutStatus?>(
            segments: const [
              ButtonSegment(
                value: PayoutStatus.requested,
                label: Text('Menunggu'),
              ),
              ButtonSegment(value: null, label: Text('Semua')),
            ],
            selected: {_status},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(minimumSize: const Size(44, 44)),
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 400) notifier.loadMore();
                return false;
              },
              child: async.when(
                loading: () => const StoreSubpageBody(
                  children: [SectionSkeleton(height: 140)],
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
                    ? StoreSubpageBody(
                        children: [
                          StoreSurface(
                            child: Text(
                              _status == PayoutStatus.requested
                                  ? 'Tidak ada pencairan yang menunggu.'
                                  : 'Belum ada pencairan.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount:
                            state.items.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) {
                          if (i == state.items.length) {
                            return const Center(
                              child: AppleActivityIndicator(size: 22),
                            );
                          }
                          final p = state.items[i];
                          return PayoutCard(
                            payout: p,
                            showStore: true,
                            trailing: p.status == PayoutStatus.requested
                                ? Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      FilledButton(
                                        onPressed: () => _markPaid(p),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                        ),
                                        child: const Text(
                                          'Tandai Sudah Ditransfer',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _reject(p),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          foregroundColor: AppColors.errorText,
                                        ),
                                        child: const Text('Tolak'),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
