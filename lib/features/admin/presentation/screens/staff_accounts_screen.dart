import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../umkm/presentation/widgets/product_form_ui.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_form_page.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/kopdes_console.dart';

/// Peran dalam kata-kata, bukan konstanta: ikon + label.
StatusPill staffRolePill(String role) => role == 'COURIER'
    ? const StatusPill(
        icon: Icons.local_shipping_outlined,
        label: 'Kurir',
        tint: Color(0xFF2F6FDB),
        text: Color(0xFF1F4FA3),
      )
    : const StatusPill(
        icon: Icons.badge_outlined,
        label: 'Pegawai',
        tint: AppColors.primary,
        text: AppColors.primaryText,
      );

/// Akun pegawai dan kurir Kopdes (`/admin/staff`).
class StaffAccountsScreen extends ConsumerWidget {
  const StaffAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Pegawai & Kurir',
            subtitle: 'Akun yang bekerja untuk Kopdes Anda',
            onBack: () => context.pop(),
            actions: [
              GlassIconButton(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Tambah akun',
                onDark: true,
                onTap: () => context.push('/admin/staff/new'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(staffAccountsProvider);
                try {
                  await ref.read(staffAccountsProvider.future);
                } catch (_) {}
              },
              child: StoreSubpageBody(
                children: [
                  async.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const SectionSkeleton(height: 220),
                    error: (e, _) => SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () => ref.invalidate(staffAccountsProvider),
                    ),
                    data: (list) => list.isEmpty
                        ? StoreSurface(
                            child: Text(
                              'Belum ada pegawai atau kurir. Buat akun '
                              'supaya mereka bisa masuk dan bekerja.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.body,
                              ),
                            ),
                          )
                        : StoreSurface(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (var i = 0; i < list.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.hairlineSoft,
                                    ),
                                  _StaffRow(account: list[i]),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin/staff/new'),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Tambah Pegawai atau Kurir'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final StaffAccount account;
  const _StaffRow({required this.account});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/admin/staff/edit', extra: account),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconTile(
                account.isCourier
                    ? Icons.local_shipping_outlined
                    : Icons.badge_outlined,
                tint: account.isCourier
                    ? const Color(0xFF2F6FDB)
                    : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    staffRolePill(account.role),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buat atau ubah akun pegawai/kurir. [existing] null = akun baru.
class StaffFormScreen extends ConsumerStatefulWidget {
  final StaffAccount? existing;
  const StaffFormScreen({super.key, this.existing});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  final _password = TextEditingController();
  late String _role = widget.existing?.role ?? 'PEGAWAI_KOPDES';

  /// null = bawaan peran (array kosong di server).
  late Set<String>? _permissions =
      (widget.existing?.permissions.isEmpty ?? true)
      ? null
      : widget.existing!.permissions.toSet();
  bool _touched = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _errors => {
    if (_name.text.trim().length < 2) 'name': 'Nama wajib diisi.',
    if (_isNew &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim()))
      'email': 'Format email tidak benar.',
    if ((_isNew || _password.text.isNotEmpty) && _password.text.length < 8)
      'password': 'Kata sandi minimal 8 karakter.',
  };

  bool get _dirty {
    final e = widget.existing;
    if (e == null) {
      return _name.text.isNotEmpty || _email.text.isNotEmpty;
    }
    final perms = _permissions ?? <String>{};
    return _name.text.trim() != e.name ||
        _phone.text.trim() != (e.phone ?? '') ||
        _password.text.isNotEmpty ||
        !(perms.length == e.permissions.length &&
            perms.containsAll(e.permissions));
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_errors.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    final service = ref.read(kopdesConsoleServiceProvider);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
      if (_role == 'PEGAWAI_KOPDES')
        'permissions': _permissions?.toList() ?? [],
      if (_isNew) ...{'email': _email.text.trim(), 'role': _role},
    };
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan akun…',
      action: () async {
        _isNew
            ? await service.createStaff(body)
            : await service.updateStaff(widget.existing!.id, body);
        ref.invalidate(staffAccountsProvider);
        return true;
      },
      successTitle: _isNew ? 'Akun Dibuat' : 'Akun Diperbarui',
      successMessage: _isNew
          ? 'Berikan email dan kata sandinya kepada yang bersangkutan '
                'untuk masuk.'
          : 'Perubahan berlaku saat pemilik akun masuk berikutnya.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  Future<void> _delete() async {
    final e = widget.existing!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun ini?'),
        content: Text(
          '${e.name} tidak akan bisa masuk lagi. Riwayat pekerjaannya tetap '
          'tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final ok = await runWithFeedback(
      context,
      waiting: 'Menghapus akun…',
      action: () async {
        await ref.read(kopdesConsoleServiceProvider).deleteStaff(e.id);
        ref.invalidate(staffAccountsProvider);
        return true;
      },
      successTitle: 'Akun Dihapus',
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _touched ? _errors : const <String, String>{};
    void changed(_) => setState(() {});

    return StoreFormPage(
      title: _isNew ? 'Tambah Akun' : 'Ubah Akun',
      subtitle: _isNew
          ? 'Pegawai atau kurir untuk Kopdes Anda'
          : widget.existing!.email,
      dirty: _dirty,
      saving: _saving,
      onSave: _dirty ? _save : null,
      children: [
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isNew) ...[
                const FieldLabel('Peran', required: true),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final r in const {
                      'PEGAWAI_KOPDES': 'Pegawai',
                      'COURIER': 'Kurir',
                    }.entries)
                      ChoiceChip(
                        label: Text(r.value),
                        selected: _role == r.key,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: (_) => setState(() => _role = r.key),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: staffRolePill(_role),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const FieldLabel('Nama', required: true),
              TextField(
                controller: _name,
                onChanged: changed,
                textCapitalization: TextCapitalization.words,
                decoration: productInputDecoration(
                  hint: 'Nama lengkap',
                  error: errors['name'],
                ),
              ),
              if (_isNew) ...[
                const SizedBox(height: AppSpacing.lg),
                const FieldLabel('Email untuk masuk', required: true),
                TextField(
                  controller: _email,
                  onChanged: changed,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: productInputDecoration(
                    hint: 'nama@contoh.id',
                    error: errors['email'],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const FieldLabel('Nomor telepon'),
              TextField(
                controller: _phone,
                onChanged: changed,
                keyboardType: TextInputType.phone,
                inputFormatters: [LengthLimitingTextInputFormatter(16)],
                decoration: productInputDecoration(hint: '0812xxxxxxxx'),
              ),
              const SizedBox(height: AppSpacing.lg),
              FieldLabel(
                _isNew ? 'Kata sandi awal' : 'Kata sandi baru',
                required: _isNew,
              ),
              TextField(
                controller: _password,
                onChanged: changed,
                obscureText: true,
                autocorrect: false,
                decoration: productInputDecoration(
                  hint: _isNew
                      ? 'Minimal 8 karakter'
                      : 'Kosongkan bila tidak diganti',
                  error: errors['password'],
                ),
              ),
            ],
          ),
        ),
        if (_role == 'PEGAWAI_KOPDES') ...[
          const SizedBox(height: AppSpacing.lg),
          const StoreSectionHeader(
            'Wewenang',
            subtitle: 'Bagian aplikasi yang boleh dibuka pegawai ini.',
          ),
          _PermissionPicker(
            selected: _permissions,
            onChanged: (v) => setState(() => _permissions = v),
          ),
        ],
        if (!_isNew) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus Akun'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.errorText,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _PermissionPicker extends ConsumerWidget {
  final Set<String>? selected;
  final ValueChanged<Set<String>?> onChanged;

  const _PermissionPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(permissionCatalogProvider)
        .when(
          loading: () => const SectionSkeleton(height: 240),
          error: (e, _) => SectionError(
            message: networkErrorMessage(e),
            onRetry: () => ref.invalidate(permissionCatalogProvider),
          ),
          data: (catalog) => StoreSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: selected == null,
                  title: const Text('Pakai wewenang bawaan pegawai'),
                  subtitle: const Text('Semua tugas harian pegawai.'),
                  onChanged: (useDefault) => onChanged(
                    useDefault ? null : catalog.map((p) => p.key).toSet(),
                  ),
                ),
                if (selected != null)
                  for (final p in catalog)
                    CheckboxListTile(
                      value: selected!.contains(p.key),
                      title: Text(p.label),
                      subtitle: Text(
                        p.description,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      onChanged: (on) => onChanged(
                        on == true
                            ? {...selected!, p.key}
                            : ({...selected!}..remove(p.key)),
                      ),
                    ),
              ],
            ),
          ),
        );
  }
}
