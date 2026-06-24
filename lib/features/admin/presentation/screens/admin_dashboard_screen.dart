import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../localization/app_localizations.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double statsAspectRatio = screenWidth < 360 ? 1.35 : 1.6;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          localizations?.translate('adminDashboard') ?? 'Dasbor Admin',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // ─── Stats Grid ───
          Text(
            'Ikhtisar Operasional',
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: statsAspectRatio,
            children: [
              _StatCard(
                label: 'Simpanan Total',
                value: 'Rp 142.5M',
                icon: Icons.account_balance_outlined,
              ),
              _StatCard(
                label: 'Pinjaman Aktif',
                value: 'Rp 82.1M',
                icon: Icons.trending_up_rounded,
              ),
              _StatCard(
                label: 'Anggota',
                value: '1.024',
                icon: Icons.people_outline_rounded,
              ),
              _StatCard(
                label: 'Transaksi Hari Ini',
                value: '124',
                icon: Icons.swap_horiz_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Pending Verifications ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verifikasi UMKM',
                style: AppTypography.caption.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Lihat Semua',
                  style: AppTypography.buttonSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _VerificationCard(
            title: 'Toko Kerajinan Bambu Lestari',
            subtitle: 'Slamet Raharjo • Sinduadi',
            time: 'Kemarin',
            context: context,
          ),
          const SizedBox(height: AppSpacing.sm),
          _VerificationCard(
            title: 'KWT Melati (Olahan Cassava)',
            subtitle: 'Sri Wahyuni • Sendangadi',
            time: '2 hari lalu',
            context: context,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Quick Controls ───
          Text(
            'Menu Kontrol',
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Kelola Inventaris',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.analytics_outlined,
            title: 'Laporan Keuangan RAT',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.tune_rounded,
            title: 'Pengaturan Sistem',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.captionSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: AppColors.muted, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final BuildContext context;

  const _VerificationCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle, style: AppTypography.captionSmall),
                  ],
                ),
              ),
              Text(time, style: AppTypography.captionSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Tolak',
                  style: AppTypography.buttonSm.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title berhasil diverifikasi'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  );
                },
                child: const Text('Setujui'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
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
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        leading: Icon(icon, color: AppColors.ink, size: 22),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
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
