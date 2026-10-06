import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_message.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/apple_feedback.dart';
import '../../../shared/widgets/apple_ui.dart';
import '../../payment/data/payment_repository.dart';
import '../../payment/presentation/payment_screen.dart';
import '../../umkm/presentation/widgets/product_form_ui.dart';
import '../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../umkm/presentation/widgets/store_page_ui.dart';
import '../data/wallet_repository.dart';

/// Batas isi ulang — cerminan `WalletService.MIN_TOPUP/MAX_TOPUP`.
const int minTopUp = 10000;
const int maxTopUp = 10000000;

String? validateTopUp(String digits) {
  if (digits.isEmpty) return 'Isi nominalnya.';
  final v = int.tryParse(digits);
  if (v == null) return 'Nominal harus angka.';
  if (v < minTopUp) return 'Minimal ${formatRupiah(minTopUp)}.';
  if (v > maxTopUp) return 'Maksimal ${formatRupiah(maxTopUp)} sekali isi.';
  return null;
}

/// Mutasi saldo berhalaman.
class WalletEntriesNotifier
    extends
        StateNotifier<
          AsyncValue<
            ({List<WalletEntry> items, bool hasMore, bool loadingMore})
          >
        > {
  final WalletRepository _repo;
  int _page = 1;

  WalletEntriesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _page = 1;
    try {
      final p = await _repo.entries();
      if (mounted) {
        state = AsyncValue.data((
          items: p.entries,
          hasMore: p.page < p.totalPages,
          loadingMore: false,
        ));
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncValue.data((
      items: cur.items,
      hasMore: true,
      loadingMore: true,
    ));
    try {
      final p = await _repo.entries(page: _page + 1);
      if (!mounted) return;
      _page++;
      state = AsyncValue.data((
        items: [...cur.items, ...p.entries],
        hasMore: p.page < p.totalPages,
        loadingMore: false,
      ));
    } catch (_) {
      if (mounted) state = AsyncValue.data(cur);
    }
  }
}

final walletEntriesProvider =
    StateNotifierProvider.autoDispose<
      WalletEntriesNotifier,
      AsyncValue<({List<WalletEntry> items, bool hasMore, bool loadingMore})>
    >((ref) => WalletEntriesNotifier(ref.watch(walletRepositoryProvider)));

/// Saldo KOMIT: saldo, isi ulang, dan riwayat mutasi.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final entries = ref.watch(walletEntriesProvider);
    final notifier = ref.read(walletEntriesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Saldo KOMIT',
            subtitle: 'Isi ulang dan bayar pesanan dari saldo',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(walletBalanceProvider);
                await notifier.load();
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 400) notifier.loadMore();
                  return false;
                },
                child: StoreSubpageBody(
                  children: [
                    balance.when(
                      loading: () => const SectionSkeleton(height: 132),
                      error: (e, _) => SectionError(
                        message:
                            'Saldo belum termuat. ${networkErrorMessage(e)}',
                        onRetry: () => ref.invalidate(walletBalanceProvider),
                      ),
                      data: (w) => StoreSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Saldo tersedia',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              formatRupiah(w.balance),
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: () => showTopUpSheet(context),
                              icon: const Icon(Icons.add_rounded),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              label: const Text('Isi Ulang Saldo'),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Saldo bisa dipakai membayar pesanan — pilih '
                              '"Saldo KOMIT" saat checkout. Pesanan yang '
                              'dibatalkan dikembalikan ke saldo.',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const StoreSectionHeader('Riwayat saldo'),
                    entries.when(
                      loading: () => const SectionSkeleton(height: 180),
                      error: (e, _) => SectionError(
                        message: networkErrorMessage(e),
                        onRetry: notifier.load,
                      ),
                      data: (s) => s.items.isEmpty
                          ? const StoreSurface(
                              child: Text('Belum ada mutasi saldo.'),
                            )
                          : StoreRowGroup(
                              rows: [
                                for (final e in s.items) _EntryRow(entry: e),
                                if (s.loadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Center(
                                      child: AppleActivityIndicator(size: 20),
                                    ),
                                  ),
                              ],
                            ),
                    ),
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

class _EntryRow extends StatelessWidget {
  final WalletEntry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final masuk = e.amount > 0;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(
            masuk ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: masuk ? AppColors.successText : AppColors.body,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${dateTimeId(e.createdAt)} · sisa ${formatRupiah(e.balanceAfter)}',
                  style: AppTypography.captionSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '${masuk ? '+' : '−'}${formatRupiah(e.amount.abs())}',
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: masuk ? AppColors.successText : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Isi ulang
// ─────────────────────────────────────────────────────────────

Future<void> showTopUpSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.canvas,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => const TopUpSheet(),
);

class TopUpSheet extends ConsumerStatefulWidget {
  const TopUpSheet({super.key});

  @override
  ConsumerState<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<TopUpSheet> {
  final _amount = TextEditingController();
  OnlineMethod _method = OnlineMethod.snap;
  bool _touched = false;
  bool _sending = false;

  static const _presets = [20000, 50000, 100000, 200000];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String get _digits => ThousandsInputFormatter.digitsOf(_amount.text);

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_sending || validateTopUp(_digits) != null) return;
    setState(() => _sending = true);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    String? id;
    final ok = await runWithFeedback(
      context,
      waiting: 'Membuat tagihan isi ulang…',
      action: () async {
        id =
            (await ref
                    .read(paymentRepositoryProvider)
                    .topUp(int.parse(_digits), _method))
                .id;
        return true;
      },
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok && id != null) {
      navigator.pop();
      router.push(PayRoutes.topUp(id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _touched ? validateTopUp(_digits) : null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Isi Ulang Saldo',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text(formatRupiah(p)),
                    selected: _digits == '$p',
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() {
                      _amount.text = formatThousands(p);
                      _touched = true;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const FieldLabel('Nominal', required: true),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              onChanged: (_) => setState(() => _touched = true),
              decoration: productInputDecoration(
                hint: 'Minimal 10.000',
                error: error,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('Rp'),
                ),
              ).copyWith(prefixIconConstraints: const BoxConstraints()),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('Bayar dengan', required: true),
            RadioGroup<OnlineMethod>(
              groupValue: _method,
              onChanged: (m) => setState(() => _method = m ?? _method),
              child: Column(
                children: [
                  for (final m in OnlineMethod.topUp)
                    RadioListTile<OnlineMethod>(
                      value: m,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.label),
                      subtitle: Text(m.hint),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Lanjut ke Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}
