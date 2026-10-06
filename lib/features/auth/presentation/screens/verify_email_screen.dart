import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 60;
  bool _verifying = false;
  bool _resending = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _startTimer(60);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _seconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _verifying) return;
    setState(() {
      _verifying = true;
      _notice = null;
    });
    final success = await ref
        .read(authProvider.notifier)
        .verifyEmail(email: widget.email, code: _code.text);
    if (!mounted || success) return;
    setState(() => _verifying = false);
    _focus.requestFocus();
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _notice = null;
    });
    final challenge = await ref
        .read(authProvider.notifier)
        .resendVerification(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    if (challenge != null) {
      _code.clear();
      _startTimer(challenge.resendAfter);
      setState(() => _notice = 'Kode baru sudah dikirim ke email Anda.');
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authProvider).errorMessage;

    if (widget.email.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 52,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pendaftaran belum ditemukan',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Isi formulir pendaftaran agar kode dapat dikirim.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Buka Pendaftaran'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali ke pendaftaran',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verifikasi Email',
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text.rich(
                    TextSpan(
                      text: 'Masukkan kode 6 angka yang dikirim ke\n',
                      children: [
                        TextSpan(
                          text: _maskEmail(widget.email),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _code,
                    focusNode: _focus,
                    enabled: !_verifying,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _verify(),
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: AppSpacing.base,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppColors.hairlineSoft),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppColors.hairlineSoft),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _notice!,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.success,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _code.text.length == 6 && !_verifying
                          ? _verify
                          : null,
                      child: _verifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Verifikasi & Masuk'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tidak menerima email?',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      TextButton(
                        onPressed: _seconds == 0 && !_resending
                            ? _resend
                            : null,
                        child: Text(
                          _resending
                              ? 'Mengirim…'
                              : _seconds > 0
                              ? 'Kirim ulang (${_seconds}d)'
                              : 'Kirim ulang',
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Ganti alamat email'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts.first;
    final visibleLength = local.length < 2 ? local.length : 2;
    final visible = local.substring(0, visibleLength);
    final hiddenLength = (local.length - visible.length).clamp(3, 12).toInt();
    final hidden = List.filled(hiddenLength, '•').join();
    return '$visible$hidden@${parts.last}';
  }
}
