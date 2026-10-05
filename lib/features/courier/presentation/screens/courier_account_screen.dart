import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_repository.dart';
import '../../data/courier_tracking.dart';

/// Rute turunan tab Akun kurir.
abstract final class CourierRoutes {
  static const security = '/courier/akun/keamanan';

  /// Percakapan dengan pengurus Kopdes. Bukan '/info/bantuan-kurir':
  /// tabel halaman informasi masih kosong, dan menautkan ke sana hanya
  /// memulangkan kurir yang sedang bingung ke halaman gagal.
  static const help = '/chat/courier';
  static String task(String id) => '/courier/tugas/$id';
}

/// Tab Akun: identitas kurir, capaian, dan pengaturan akun.
class CourierAccountScreen extends ConsumerWidget {
  const CourierAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(courierSummaryProvider);
    final tracking = ref.watch(courierTrackingProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SellerPageChrome(
        title: 'Akun Kurir',
        subtitle: user?.kopdesName == null
            ? 'Profil dan pengaturan'
            : 'Kurir ${user!.kopdesName}',
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(courierSummaryProvider);
            try {
              await ref.read(courierSummaryProvider.future);
            } catch (_) {}
          },
          child: StoreSubpageBody(
            children: [
              StoreSurface(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconTile(
                      Icons.two_wheeler_rounded,
                      tint: AppColors.primary,
                      size: 56,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Kurir',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (user?.email != null)
                            Text(
                              user!.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall.copyWith(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          // Status siaran, bukan sakelar "Online" palsu.
                          // Yang menentukan kurir terlihat atau tidak adalah
                          // tugas yang sedang dibawanya, bukan tombol.
                          tracking.isBroadcasting
                              ? const StatusPill(
                                  icon: Icons.podcasts_rounded,
                                  label: 'Posisi sedang dikirim',
                                  tint: AppColors.success,
                                  text: AppColors.successText,
                                )
                              : const StatusPill(
                                  icon: Icons.pause_circle_outline_rounded,
                                  label: 'Tidak sedang mengantar',
                                  tint: AppColors.muted,
                                  text: AppColors.body,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              summary.when(
                skipLoadingOnRefresh: true,
                loading: () => const SectionSkeleton(height: 92),
                error: (e, _) => SectionError(
                  message: 'Capaian belum termuat. ${networkErrorMessage(e)}',
                  onRetry: () => ref.invalidate(courierSummaryProvider),
                ),
                data: (s) => StoreSurface(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Antaran selesai',
                          value: '${s.deliveredTotal}',
                        ),
                      ),
                      const SizedBox(
                        height: 36,
                        child: VerticalDivider(
                          width: 1,
                          color: AppColors.hairlineSoft,
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Sedang dibawa',
                          value: '${s.activeTasks}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              const StoreSectionHeader('Data akun'),
              StoreRowGroup(
                rows: [
                  StoreRow(
                    icon: Icons.badge_outlined,
                    title: 'Nama',
                    value: user?.name ?? '—',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  StoreRow(
                    icon: Icons.phone_outlined,
                    title: 'Nomor telepon',
                    value: (user?.phone.isNotEmpty ?? false)
                        ? user!.phone
                        : 'Belum diisi',
                    placeholder: !(user?.phone.isNotEmpty ?? false),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  // Penugasan Kopdes bukan milik kurir untuk diubah: itu
                  // yang menentukan tugas desa mana yang ia lihat.
                  StoreRow(
                    icon: Icons.account_balance_outlined,
                    title: 'Kopdes',
                    value: user?.kopdesName ?? 'Belum ditugaskan',
                    placeholder: user?.kopdesName == null,
                    onTap: () => _managedByAdmin(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              const StoreSectionHeader('Pengaturan'),
              StoreRowGroup(
                rows: [
                  StoreRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifikasi',
                    value: 'Pemberitahuan di perangkat ini',
                    onTap: () => context.push('/notifications'),
                  ),
                  StoreRow(
                    icon: Icons.shield_outlined,
                    title: 'Keamanan akun',
                    value: 'Kata sandi dan keluar',
                    onTap: () => context.push(CourierRoutes.security),
                  ),
                  StoreRow(
                    icon: Icons.support_agent_rounded,
                    title: 'Hubungi pengurus Kopdes',
                    value: 'Tanya bila ada kendala di jalan',
                    onTap: () => context.push(CourierRoutes.help),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Penugasan Kopdes dikelola pengurus lewat halaman Pegawai & Kurir.
  /// Menyediakan form di sini akan menjanjikan perubahan yang tidak punya
  /// endpoint-nya.
  void _managedByAdmin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Penugasan Kopdes diubah oleh pengurus lewat menu Pegawai & Kurir.',
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.captionSmall.copyWith(
          fontSize: 12,
          color: AppColors.muted,
        ),
      ),
    ],
  );
}
