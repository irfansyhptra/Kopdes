import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../umkm/presentation/widgets/product_form_ui.dart';
import '../../../umkm/presentation/widgets/store_form_page.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';

String? validateProfileName(String v) {
  final t = v.trim();
  if (t.isEmpty) return 'Nama wajib diisi.';
  if (t.length < 3) return 'Nama minimal 3 huruf.';
  return null;
}

/// Nomor HP boleh kosong; bila diisi harus nomor ponsel Indonesia.
String? validateProfilePhone(String v) {
  final t = v.replaceAll(RegExp(r'[\s-]'), '');
  if (t.isEmpty) return null;
  return RegExp(r'^(\+62|62|0)8\d{7,12}$').hasMatch(t)
      ? null
      : 'Gunakan nomor ponsel Indonesia, mis. 0812xxxxxxx.';
}

/// Data pribadi: nama dan nomor HP. Email tidak bisa diubah dari sini —
/// ia identitas masuk akun.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _user = ref.read(authProvider).user;
  late final _name = TextEditingController(text: _user?.name ?? '');
  late final _phone = TextEditingController(text: _user?.phone ?? '');
  bool _saving = false;
  bool _touched = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != (_user?.name ?? '') ||
      _phone.text.trim() != (_user?.phone ?? '');

  Future<void> _save() async {
    setState(() => _touched = true);
    if (validateProfileName(_name.text) != null ||
        validateProfilePhone(_phone.text) != null ||
        _saving) {
      return;
    }
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan profil…',
      action: () async {
        await ref
            .read(authProvider.notifier)
            .updateProfile(
              name: _name.text.trim(),
              phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
            );
        // Notifier menyimpan galatnya alih-alih melempar.
        final error = ref.read(authProvider).errorMessage;
        if (error != null) throw Exception(error);
        return true;
      },
      successTitle: 'Profil Tersimpan',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final nameError = _touched ? validateProfileName(_name.text) : null;
    final phoneError = _touched ? validateProfilePhone(_phone.text) : null;

    return StoreFormPage(
      title: 'Data Pribadi',
      subtitle: 'Nama dan nomor yang dilihat penjual & kurir',
      dirty: _dirty,
      saving: _saving,
      onSave: _dirty ? _save : null,
      children: [
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Nama lengkap', required: true),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: productInputDecoration(error: nameError),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FieldLabel('Nomor HP'),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: productInputDecoration(
                  hint: '0812xxxxxxxx',
                  error: phoneError,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FieldLabel('Email'),
              Text(
                _user?.email ?? '—',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
              ),
              Text(
                'Email dipakai untuk masuk dan tidak bisa diubah di sini.',
                style: AppTypography.captionSmall.copyWith(
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
