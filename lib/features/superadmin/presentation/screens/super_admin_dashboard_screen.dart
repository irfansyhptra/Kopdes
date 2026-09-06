import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../admin/presentation/widgets/admin_ui.dart';
import '../../data/superadmin_models.dart';
import '../providers/superadmin_providers.dart';

// Dasbor Super Admin: ikhtisar sistem + pintu masuk pengelolaan.
class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final overview = ref.watch(overviewProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Super Admin',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ink),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(overviewProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            Text(
              'Halo, ${user?.name ?? 'Super Admin'}',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ikhtisar seluruh sistem KOPDES.',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            overview.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => AdminCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gagal memuat ikhtisar:\n$e',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(overviewProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (o) => _OverviewSection(overview: o),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Menu Pengelolaan',
              style: AppTypography.caption.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _MenuTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Kelola Akun Kopdes',
              subtitle: 'Buat & kelola Admin / Pegawai Kopdes',
              onTap: () => context.push('/super-admin/accounts'),
            ),
            _MenuTile(
              icon: Icons.groups_outlined,
              title: 'Direktori Pengguna',
              subtitle: 'Semua user terdaftar',
              onTap: () => context.push('/super-admin/users'),
            ),
            _MenuTile(
              icon: Icons.dashboard_customize_outlined,
              title: 'Panel Admin Kopdes',
              subtitle: 'Kelola produk, mitra, pesanan',
              onTap: () => context.push('/admin'),
            ),
            const SizedBox(height: AppSpacing.section),
          ],
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
          'Yakin ingin keluar?',
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

class _OverviewSection extends StatelessWidget {
  final Overview overview;
  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              label: 'Total Pendapatan',
              value: rupiah(overview.totalRevenue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            _StatCard(
              label: 'Total Pesanan',
              value: '${overview.totalOrders}',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
            _StatCard(
              label: 'Total Produk',
              value: '${overview.totalProducts}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primaryActive,
              hint:
                  '${overview.retailProducts} ritel • ${overview.umkmProducts} UMKM',
            ),
            _StatCard(
              label: 'Total Pengguna',
              value: '${overview.totalUsers}',
              icon: Icons.groups_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mitra UMKM',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (overview.pendingMitra > 0)
                    StatusChip(
                      label: '${overview.pendingMitra} menunggu',
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${overview.totalMitra} mitra terdaftar',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (overview.usersByRole.isNotEmpty)
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengguna per Peran',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...overview.usersByRole.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            roleLabel(e.key),
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.body,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: AppTypography.captionSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? hint;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(label, style: AppTypography.captionSmall),
          if (hint != null)
            Text(
              hint!,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 9,
                color: AppColors.mutedSoft,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.soft,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(subtitle, style: AppTypography.captionSmall),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.hairline,
        ),
        onTap: onTap,
      ),
    );
  }
}
