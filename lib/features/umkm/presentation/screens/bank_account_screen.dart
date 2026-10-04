import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../data/payout_repository.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/store_form_page.dart';
import '../widgets/store_page_ui.dart';

/// Batas rekening — cerminan `UpsertBankAccountDto`.
class BankAccountRules {
  static String? bank(String v) {
    final t = v.trim();
    if (t.length < 2) return 'Isi nama bank.';
    if (t.length > 60) return 'Nama bank terlalu panjang.';
    return null;
  }

  static String? number(String v) {
    final t = v.replaceAll(RegExp(r'[\s-]'), '');
    if (t.isEmpty) return 'Isi nomor rekening.';
    if (!RegExp(r'^\d{6,20}$').hasMatch(t)) {
      return 'Nomor rekening harus 6–20 digit angka.';
    }
    return null;
  }

  static String? holder(String v) {
    final t = v.trim();
    if (t.length < 3) return 'Isi nama pemilik rekening.';
    if (t.length > 80) return 'Nama pemilik terlalu panjang.';
    return null;
  }
}

/// Bank yang paling umum dipakai usaha di Aceh — hanya saran isian.
const _commonBanks = ['BSI', 'Bank Aceh Syariah', 'BRI', 'BNI', 'Mandiri'];

class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  BankAccountInfo? _original;
  bool _loaded = false;
  bool _saving = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(bankAccountProvider, (_, next) {
      if (_loaded || !next.hasValue) return;
      final a = next.value;
      setState(() {
        _loaded = true;
        _original = a;
        _bank.text = a?.bankName ?? '';
        _number.text = a?.accountNumber ?? '';
        _holder.text = a?.accountHolder ?? '';
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _bank.dispose();
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _loaded &&
      (_bank.text.trim() != (_original?.bankName ?? '') ||
          _number.text.trim() != (_original?.accountNumber ?? '') ||
          _holder.text.trim() != (_original?.accountHolder ?? ''));

  Map<String, String> get _errors => {
    'bank': ?BankAccountRules.bank(_bank.text),
    'number': ?BankAccountRules.number(_number.text),
    'holder': ?BankAccountRules.holder(_holder.text),
  };

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan rekening…',
      action: () async {
        await ref
            .read(payoutRepositoryProvider)
            .saveBankAccount(
              bankName: _bank.text.trim(),
              accountNumber: _number.text.replaceAll(RegExp(r'[\s-]'), ''),
              accountHolder: _holder.text.trim(),
            );
        ref
          ..invalidate(bankAccountProvider)
          ..invalidate(payoutSummaryProvider);
        return true;
      },
      successTitle: 'Rekening Tersimpan',
      successMessage: 'Pencairan berikutnya ditransfer ke rekening ini.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bankAccountProvider);
    final errors = _touched ? _errors : const <String, String>{};

    return StoreFormPage(
      title: 'Rekening Pencairan',
      subtitle: 'Tujuan transfer saldo toko',
      dirty: _dirty,
      saving: _saving,
      onSave: _dirty ? _save : null,
      children: [
        if (!_loaded)
          async.hasError
              ? SectionError(
                  message: networkErrorMessage(async.error!),
                  onRetry: () => ref.invalidate(bankAccountProvider),
                )
              : const SectionSkeleton(height: 360)
        else
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Nama bank', required: true),
                TextField(
                  controller: _bank,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: productInputDecoration(
                    hint: 'Contoh: BSI',
                    error: errors['bank'],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final b in _commonBanks)
                      ActionChip(
                        label: Text(b),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onPressed: () => setState(() => _bank.text = b),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('Nomor rekening', required: true),
                TextField(
                  controller: _number,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: productInputDecoration(
                    hint: 'Hanya angka',
                    error: errors['number'],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('Nama pemilik rekening', required: true),
                TextField(
                  controller: _holder,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: productInputDecoration(
                    hint: 'Sesuai buku tabungan',
                    error: errors['holder'],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Periksa lagi sebelum menyimpan. Transfer ke rekening yang '
                  'salah tidak bisa dibatalkan pengurus Kopdes.',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
