import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/admin_ui.dart';

// Profil Admin Kopdes: identitas pengelola + logout.
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: adminAppBar(context, 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                (user?.name.isNotEmpty ?? false)
                    ? user!.name[0].toUpperCase()
                    : 'A',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              user?.name ?? 'Admin Kopdes',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: StatusChip(
              label: _roleLabel(user?.role),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AdminCard(
            child: Column(
              children: [
                _infoTile(Icons.email_outlined, 'Email', user?.email ?? '-'),
                Divider(color: AppColors.hairlineSoft, height: 1),
                _infoTile(
                  Icons.phone_outlined,
                  'Telepon',
                  (user?.phone.isNotEmpty ?? false) ? user!.phone : '-',
                ),
                Divider(color: AppColors.hairlineSoft, height: 1),
                _infoTile(
                  Icons.store_mall_directory_outlined,
                  'Koperasi',
                  'KOPDES',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Keluar',
              style: AppTypography.buttonMd.copyWith(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: AppColors.error.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN_KOPDES':
        return 'Admin Kopdes';
      default:
        return role ?? '-';
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.muted, size: 20),
      title: Text(label, style: AppTypography.captionSmall),
      subtitle: Text(
        value,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        title: Text(
          'Keluar',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Yakin ingin keluar dari akun?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
