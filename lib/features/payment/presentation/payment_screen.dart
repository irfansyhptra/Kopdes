import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/error_message.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/apple_ui.dart';
import '../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../umkm/presentation/widgets/store_page_ui.dart';
import '../../wallet/data/wallet_repository.dart';
import '../data/payment_repository.dart';

/// Rute pembayaran.
abstract final class PayRoutes {
  static String order(String orderId, {String method = 'QRIS'}) =>
      '/pay/order/$orderId?method=$method';
  static String topUp(String topUpId) => '/pay/topup/$topUpId';
}

/// Apa yang sedang dibayar.
typedef PayTarget = ({bool topUp, String id, String method});

/// Sesi pembayaran: memuat tagihan, lalu menanyakan statusnya berkala
/// sampai lunas, kedaluwarsa, atau gagal.
///
/// Webhook Midtrans yang mengubah status di server; aplikasi hanya bertanya.
/// Tiap 5 detik = 12 kali per menit, di bawah batas 30 `check-status`.
class PaymentSession extends StateNotifier<AsyncValue<PaymentInstructions>> {
  final PaymentRepository _repo;
  PayTarget _target;
  Timer? _timer;
  bool _busy = false;

  static const interval = Duration(seconds: 5);

  PaymentSession(this._repo, this._target) : super(const AsyncValue.loading()) {
    start();
  }

  Future<void> start() async {
    state = const AsyncValue.loading();
    try {
      final first = _target.topUp
          ? await _repo.topUpStatus(_target.id)
          : await _repo.payOrder(
              _target.id,
              OnlineMethod.parse(_target.method),
            );
      if (!mounted) return;
      state = AsyncValue.data(first);
      _schedule();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Ganti metode (pesanan saja) — server membuat tagihan baru.
  Future<void> changeMethod(OnlineMethod m) async {
    _target = (topUp: false, id: _target.id, method: m.wire);
    _timer?.cancel();
    await start();
  }

  void _schedule() {
    _timer?.cancel();
    if (state.valueOrNull?.status != PayStatus.pending) return;
    _timer = Timer.periodic(interval, (_) => check());
  }

  /// Tanya status sekarang (juga dari tombol "Cek Status").
  Future<void> check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final next = _target.topUp
          ? await _repo.topUpStatus(_target.id)
          : await _repo.checkOrder(_target.id);
      if (!mounted) return;
      // Instruksi lama dipertahankan bila respons cek status tidak memuatnya.
      final prev = state.valueOrNull;
      state = AsyncValue.data(
        PaymentInstructions(
          status: next.status,
          amount: next.amount != 0 ? next.amount : (prev?.amount ?? 0),
          method: next.method,
          qrCodeUrl: next.qrCodeUrl ?? prev?.qrCodeUrl,
          deeplinkUrl: next.deeplinkUrl ?? prev?.deeplinkUrl,
          vaNumber: next.vaNumber ?? prev?.vaNumber,
          bank: next.bank ?? prev?.bank,
          billKey: next.billKey ?? prev?.billKey,
          billerCode: next.billerCode ?? prev?.billerCode,
          expiresAt: next.expiresAt ?? prev?.expiresAt,
        ),
      );
      if (next.status != PayStatus.pending) _timer?.cancel();
    } catch (_) {
      // Satu tarikan gagal bukan alasan mengosongkan instruksi bayar.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final paymentSessionProvider = StateNotifierProvider.autoDispose
    .family<PaymentSession, AsyncValue<PaymentInstructions>, PayTarget>(
      (ref, target) =>
          PaymentSession(ref.watch(paymentRepositoryProvider), target),
    );

// ─────────────────────────────────────────────────────────────
// Layar
// ─────────────────────────────────────────────────────────────

class PaymentScreen extends ConsumerWidget {
  final PayTarget target;
  const PaymentScreen({super.key, required this.target});

  Future<void> _pickMethod(BuildContext context, WidgetRef ref) async {
    final m = await showModalBottomSheet<OnlineMethod>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.base),
              child: Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final m in OnlineMethod.values)
              ListTile(
                minTileHeight: 56,
                title: Text(m.label),
                subtitle: Text(m.hint),
                trailing: m.wire == target.method
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheet, m),
              ),
          ],
        ),
      ),
    );
    if (m != null) {
      await ref.read(paymentSessionProvider(target).notifier).changeMethod(m);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentSessionProvider(target));
    final session = ref.read(paymentSessionProvider(target).notifier);

    // Lunas: saldo & daftar pesanan di layar lain ikut menyusul.
    ref.listen(paymentSessionProvider(target), (prev, next) {
      if (prev?.valueOrNull?.status != PayStatus.paid &&
          next.valueOrNull?.status == PayStatus.paid) {
        ref.invalidate(walletBalanceProvider);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: target.topUp ? 'Isi Ulang Saldo' : 'Pembayaran',
            subtitle: 'Diproses aman oleh Midtrans',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: async.when(
              loading: () => const StoreSubpageBody(
                children: [SectionSkeleton(height: 420)],
              ),
              error: (e, _) => StoreSubpageBody(
                children: [
                  SectionError(
                    message:
                        'Tagihan belum berhasil dibuat. ${networkErrorMessage(e)}',
                    onRetry: session.start,
                  ),
                ],
              ),
              data: (p) => StoreSubpageBody(
                children: [
                  _AmountCard(pay: p),
                  const SizedBox(height: AppSpacing.md),
                  switch (p.status) {
                    PayStatus.pending => _Instructions(
                      pay: p,
                      onCheck: session.check,
                      onChangeMethod: target.topUp
                          ? null
                          : () => _pickMethod(context, ref),
                    ),
                    PayStatus.paid => _Done(
                      topUp: target.topUp,
                      onDone: () => target.topUp
                          ? context.pop()
                          : context.go('/orders/${target.id}'),
                    ),
                    _ => _Failed(
                      expired: p.status == PayStatus.expired,
                      topUp: target.topUp,
                      onRetry: target.topUp
                          ? () => context.pop()
                          : session.start,
                    ),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final PaymentInstructions pay;
  const _AmountCard({required this.pay});

  @override
  Widget build(BuildContext context) {
    final pill = switch (pay.status) {
      PayStatus.pending => const StatusPill(
        icon: Icons.hourglass_top_rounded,
        label: 'Menunggu pembayaran',
        tint: AppColors.warning,
        text: AppColors.warningText,
      ),
      PayStatus.paid => const StatusPill(
        icon: Icons.check_circle_rounded,
        label: 'Lunas',
        tint: AppColors.success,
        text: AppColors.successText,
      ),
      PayStatus.expired => const StatusPill(
        icon: Icons.timer_off_outlined,
        label: 'Kedaluwarsa',
        tint: AppColors.muted,
        text: AppColors.body,
      ),
      PayStatus.failed => const StatusPill(
        icon: Icons.cancel_outlined,
        label: 'Gagal',
        tint: AppColors.error,
        text: AppColors.errorText,
      ),
    };
    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${pay.method.label}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
          ),
          Text(
            formatRupiah(pay.amount),
            style: AppTypography.titleLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              pill,
              if (pay.status == PayStatus.pending && pay.expiresAt != null)
                _Countdown(until: pay.expiresAt!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  final DateTime until;
  const _Countdown({required this.until});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _t = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(DateTime.now());
    final s = left.isNegative ? Duration.zero : left;
    final h = s.inHours;
    final mm = (s.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (s.inSeconds % 60).toString().padLeft(2, '0');
    return StatusPill(
      icon: Icons.timer_outlined,
      label: 'Sisa ${h > 0 ? '$h:' : ''}$mm:$ss',
      tint: AppColors.muted,
      text: AppColors.body,
    );
  }
}

class _Instructions extends StatelessWidget {
  final PaymentInstructions pay;
  final VoidCallback onCheck;
  final VoidCallback? onChangeMethod;

  const _Instructions({
    required this.pay,
    required this.onCheck,
    required this.onChangeMethod,
  });

  Future<void> _copy(BuildContext context, String v, String what) async {
    await Clipboard.setData(ClipboardData(text: v));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$what disalin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _codeRow(BuildContext context, String label, String value) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.captionSmall),
            SelectableText(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: () => _copy(context, value, label),
        icon: const Icon(Icons.copy_rounded, size: 18),
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        label: const Text('Salin'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = pay;
    final children = <Widget>[];

    if (p.qrCodeUrl != null) {
      children.addAll([
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppleRadii.control),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Image.network(
              p.qrCodeUrl!,
              width: 240,
              height: 240,
              semanticLabel: 'Kode QR pembayaran',
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 240,
                height: 240,
                child: Center(
                  child: Text(
                    'Kode QR belum termuat. Tekan "Cek Status" atau coba lagi.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          p.method == OnlineMethod.qris
              ? 'Buka aplikasi bank atau e-wallet apa pun, pilih Scan/QRIS, '
                    'lalu arahkan kamera ke kode di atas.'
              : 'Scan dengan aplikasi ${p.method.label}, atau tekan tombol di bawah.',
          textAlign: TextAlign.center,
        ),
      ]);
    }

    if (p.deeplinkUrl != null) {
      children.addAll([
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(p.deeplinkUrl!),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new_rounded),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          label: Text('Buka ${p.method.label}'),
        ),
      ]);
    }

    if (p.vaNumber != null) {
      children.addAll([
        Text(
          'Transfer ke Virtual Account ${(p.bank ?? '').toUpperCase()}',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        _codeRow(context, 'Nomor Virtual Account', p.vaNumber!),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nominal harus persis ${formatRupiah(p.amount)}. Status berubah '
          'otomatis setelah transfer diterima.',
          style: AppTypography.captionSmall,
        ),
      ]);
    }

    if (p.billKey != null && p.billerCode != null) {
      children.addAll([
        _codeRow(context, 'Kode perusahaan', p.billerCode!),
        const SizedBox(height: AppSpacing.sm),
        _codeRow(context, 'Kode bayar', p.billKey!),
      ]);
    }

    if (children.isEmpty) {
      children.add(
        const Text(
          'Instruksi pembayaran belum tersedia. Tekan "Cek Status" sebentar '
          'lagi.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Halaman ini memeriksa status pembayaran otomatis. Anda boleh '
          'menutupnya — tagihan tetap tercatat di pesanan Anda.',
          textAlign: TextAlign.center,
          style: AppTypography.captionSmall.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onCheck,
          icon: const Icon(Icons.refresh_rounded),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          label: const Text('Cek Status Pembayaran'),
        ),
        if (onChangeMethod != null)
          TextButton(
            onPressed: onChangeMethod,
            style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
            child: const Text('Ganti Metode Pembayaran'),
          ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  final bool topUp;
  final VoidCallback onDone;
  const _Done({required this.topUp, required this.onDone});

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Column(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 56,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pembayaran Diterima',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(
          topUp
              ? 'Saldo Anda sudah bertambah.'
              : 'Pesanan Anda diteruskan ke penjual untuk disiapkan.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.base),
        FilledButton(
          onPressed: onDone,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(topUp ? 'Kembali ke Saldo' : 'Lihat Pesanan'),
        ),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  final bool expired;
  final bool topUp;
  final VoidCallback onRetry;
  const _Failed({
    required this.expired,
    required this.topUp,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Column(
      children: [
        Icon(
          expired ? Icons.timer_off_outlined : Icons.cancel_outlined,
          size: 48,
          color: AppColors.muted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          expired ? 'Tagihan Kedaluwarsa' : 'Pembayaran Gagal',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          expired
              ? 'Batas waktu bayar habis dan belum ada uang yang terpotong.'
              : 'Pembayaran tidak berhasil dan belum ada uang yang terpotong.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.base),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(topUp ? 'Isi Ulang Lagi' : 'Bayar Ulang'),
        ),
      ],
    ),
  );
}
