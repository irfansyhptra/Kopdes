import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/payout_repository.dart';
import 'product_form_ui.dart';

/// Membuka lembar "Tarik saldo". Hanya dipanggil bila `canWithdraw`.
Future<void> showWithdrawSheet(
  BuildContext context, {
  required PayoutSummary summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.card),
      ),
    ),
    builder: (_) => WithdrawSheet(summary: summary),
  );
}

/// Validasi nominal — dipisah supaya bisa diuji tanpa layar.
String? validateWithdrawal(String digits, PayoutSummary s) {
  if (digits.isEmpty) return 'Isi nominal yang ingin ditarik.';
  final v = int.tryParse(digits);
  if (v == null) return 'Nominal harus angka.';
  if (v < s.minWithdrawal) {
    return 'Minimal ${formatRupiah(s.minWithdrawal)}.';
  }
  if (v > s.available) {
    return 'Saldo tersedia hanya ${formatRupiah(s.available)}.';
  }
  return null;
}

class WithdrawSheet extends ConsumerStatefulWidget {
  final PayoutSummary summary;
  const WithdrawSheet({super.key, required this.summary});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  // Diisi saldo tersedia: kebanyakan orang menarik semuanya.
  late final _amount = TextEditingController(
    text: formatThousands(widget.summary.available.floor()),
  );
  bool _touched = false;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String get _digits => ThousandsInputFormatter.digitsOf(_amount.text);

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_sending || validateWithdrawal(_digits, widget.summary) != null) {
      return;
    }
    final amount = int.parse(_digits);
    final bank = widget.summary.bankAccount!;
    setState(() => _sending = true);

    final navigator = Navigator.of(context);
    final ok = await runWithFeedback(
      context,
      waiting: 'Mengajukan pencairan…',
      action: () async {
        await ref.read(payoutRepositoryProvider).request(amount);
        return true;
      },
      successTitle: 'Pencairan Diajukan',
      successMessage:
          'Pengurus Kopdes akan mentransfer ${formatRupiah(amount)} ke '
          '${bank.bankName} ${bank.accountNumber}. Statusnya bisa dilihat di '
          'Riwayat.',
    );
    // Saldo dihitung ulang server, baik berhasil maupun gagal (mis. saldo
    // berubah karena pesanan dibatalkan di antaranya).
    ref.invalidate(payoutSummaryProvider);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final bank = s.bankAccount!;
    final error = _touched ? validateWithdrawal(_digits, s) : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tarik Saldo',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tersedia ${formatRupiah(s.available)} · minimal '
              '${formatRupiah(s.minWithdrawal)}',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('Nominal', required: true),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              onChanged: (_) => setState(() => _touched = true),
              decoration: productInputDecoration(
                error: error,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('Rp'),
                ),
              ).copyWith(prefixIconConstraints: const BoxConstraints()),
            ),
            const SizedBox(height: AppSpacing.base),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppleRadii.control),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Ke ${bank.bankName} ${bank.accountNumber}\n'
                      'a.n. ${bank.accountHolder}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: AppColors.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Transfer dilakukan pengurus Kopdes secara manual. Selama '
              'diproses, pengajuan baru belum bisa dibuat.',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
              ),
              child: Text(_sending ? 'Mengajukan…' : 'Ajukan Pencairan'),
            ),
          ],
        ),
      ),
    );
  }
}
