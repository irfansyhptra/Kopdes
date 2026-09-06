import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../admin/presentation/widgets/admin_ui.dart';
import '../../data/superadmin_models.dart';
import '../providers/superadmin_providers.dart';

// Super Admin membuat & mengelola akun staf Kopdes (Admin & Pegawai).
class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProvider);
    final action = ref.watch(superAdminActionProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: adminAppBar(context, 'Akun Kopdes'),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Buat Akun'),
            onPressed: () => _openCreateForm(context, ref),
          ),
          body: AdminAsyncList<AppUser>(
            value: staff,
            onRefresh: () => ref.invalidate(staffProvider),
            emptyTitle:
                'Belum ada akun staf. Tekan "Buat Akun" untuk menambahkan.',
            emptyIcon: Icons.badge_outlined,
            itemBuilder: (u) => _StaffCard(user: u, ref: ref),
          ),
        ),
        ActionOverlay(visible: action is AsyncLoading),
      ],
    );
  }

  void _openCreateForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateStaffForm(ref: ref),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;
  const _StaffCard({required this.user, required this.ref});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        title: Text(
          'Hapus Akun',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Hapus akun "${user.name}" (${user.email})?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await ref
          .read(superAdminActionProvider.notifier)
          .deleteStaff(user.id);
      if (context.mounted) {
        showSnack(
          context,
          success ? 'Akun dihapus' : 'Gagal menghapus akun',
          error: !success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'ADMIN_KOPDES';
    return AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.badge_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(user.email, style: AppTypography.captionSmall),
                const SizedBox(height: 4),
                StatusChip(
                  label: roleLabel(user.role),
                  color: isAdmin ? AppColors.primary : AppColors.primaryActive,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}

class _CreateStaffForm extends StatefulWidget {
  final WidgetRef ref;
  const _CreateStaffForm({required this.ref});

  @override
  State<_CreateStaffForm> createState() => _CreateStaffFormState();
}

class _CreateStaffFormState extends State<_CreateStaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'ADMIN_KOPDES';
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final notifier = widget.ref.read(superAdminActionProvider.notifier);
    final ok = await notifier.createStaff(
      email: _email.text.trim(),
      password: _password.text,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      role: _role,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context);
      showSnack(context, 'Akun ${roleLabel(_role)} berhasil dibuat');
    } else {
      final err = widget.ref.read(superAdminActionProvider);
      final msg = err is AsyncError
          ? notifier.errorMessage(err.error)
          : 'Gagal membuat akun';
      showSnack(context, msg, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Buat Akun Kopdes',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _field(
              _name,
              'Nama lengkap',
              Icons.person_outline,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              _email,
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailV,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              _phone,
              'No. telepon (opsional)',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              _password,
              'Kata sandi (min. 6)',
              Icons.lock_outline,
              obscure: _obscure,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Peran',
              style: AppTypography.captionSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: _decoration('Pilih peran', Icons.security_outlined),
              items: const [
                DropdownMenuItem(
                  value: 'ADMIN_KOPDES',
                  child: Text('Admin Kopdes'),
                ),
                DropdownMenuItem(
                  value: 'PEGAWAI_KOPDES',
                  child: Text('Pegawai Kopdes'),
                ),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'ADMIN_KOPDES'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Buat Akun'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
  String? _emailV(String? v) =>
      (v == null || !v.contains('@')) ? 'Email tidak valid' : null;

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(label, icon).copyWith(suffixIcon: suffix),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
    filled: true,
    fillColor: AppColors.surfaceSoft,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
  );
}
