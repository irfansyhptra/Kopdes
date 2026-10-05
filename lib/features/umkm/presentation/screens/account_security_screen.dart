import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../auth/data/password_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/store_form_page.dart';
import '../widgets/store_page_ui.dart';

/// Aturan kata sandi baru — cerminan `ChangePasswordDto`.
String? validateNewPassword(String v) {
  if (v.length < 8) return 'Minimal 8 karakter.';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Gunakan huruf dan angka.';
  }
  return null;
}

/// Keamanan akun: ganti kata sandi dan keluar.
class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _saving = false;
  bool _touched = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _current.text.isNotEmpty ||
      _next.text.isNotEmpty ||
      _confirm.text.isNotEmpty;

  Map<String, String> get _errors => {
    if (_current.text.isEmpty) 'current': 'Isi kata sandi saat ini.',
    'next': ?validateNewPassword(_next.text),
    if (_confirm.text != _next.text)
      'confirm': 'Tidak sama dengan kata sandi baru.',
  };

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      waiting: 'Mengganti kata sandi…',
      action: () async {
        await changePassword(
          ref,
          currentPassword: _current.text,
          newPassword: _next.text,
        );
        return true;
      },
      successTitle: 'Kata Sandi Diganti',
      successMessage: 'Perangkat lain yang memakai akun ini sudah dikeluarkan.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleRadii.tile),
        ),
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk membuka akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yes == true) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _touched ? _errors : const <String, String>{};
    Widget field(
      TextEditingController c,
      String label,
      String key, {
      String? hint,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label, required: true),
        TextField(
          controller: c,
          obscureText: !_show,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
          decoration: productInputDecoration(hint: hint, error: errors[key]),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );

    return StoreFormPage(
      title: 'Keamanan Akun',
      subtitle: 'Kata sandi dan sesi masuk',
      dirty: _dirty,
      saving: _saving,
      saveLabel: 'Ganti Kata Sandi',
      onSave: _dirty ? _save : null,
      children: [
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(_current, 'Kata sandi saat ini', 'current'),
              field(
                _next,
                'Kata sandi baru',
                'next',
                hint: 'Minimal 8 karakter, huruf dan angka',
              ),
              field(_confirm, 'Ulangi kata sandi baru', 'confirm'),
              CheckboxListTile(
                value: _show,
                onChanged: (v) => setState(() => _show = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Tampilkan kata sandi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        StoreRowGroup(
          rows: [
            ApplePressable(
              onTap: _logout,
              semanticLabel: 'Keluar dari akun',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.errorText,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Keluar dari akun',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
