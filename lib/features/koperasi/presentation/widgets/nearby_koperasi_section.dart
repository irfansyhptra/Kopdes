import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../location/domain/user_location.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/directions.dart';
import '../providers/koperasi_provider.dart';
import 'koperasi_card.dart';
import 'location_prompt.dart';

/// Section "Kopdes Terdekat" di beranda.
///
/// Punya state sendiri: kegagalan di sini tidak menggagalkan section lain.
class NearbyKoperasiSection extends ConsumerWidget {
  const NearbyKoperasiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationStatus = ref.watch(locationProvider.select((s) => s.status));
    final hasCoordinates = ref.watch(userCoordinatesProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: 'Kopdes Terdekat',
          actionLabel: 'Lihat Lainnya',
          onAction: () => context.push('/koperasi'),
        ),
        const SizedBox(height: AppSpacing.md),

        // Lokasi mengurutkan, tidak menyaring: daftarnya tampil dengan atau
        // tanpa koordinat. Ajakan mengaktifkan lokasi berdiri di atasnya —
        // dulu ia menggantikan daftar, sehingga Kopdes yang terdaftar
        // terbaca seperti tidak ada bagi yang menolak izin.
        if (!hasCoordinates && !_isResolving(locationStatus)) ...[
          const LocationPrompt(),
          const SizedBox(height: AppSpacing.md),
        ],
        const _NearbyList(),
      ],
    );
  }
}

/// Lokasi masih dicari: menampilkan ajakan di sini akan berkedip sebentar
/// lalu hilang begitu koordinatnya tiba.
bool _isResolving(LocationStatus status) =>
    status == LocationStatus.initial ||
    status == LocationStatus.checkingService ||
    status == LocationStatus.requestingPermission ||
    status == LocationStatus.loadingLocation;

class _NearbyList extends ConsumerWidget {
  const _NearbyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyKoperasiProvider);

    return async.when(
      loading: () => const _CardSkeleton(),
      error: (_, __) => _SectionMessage(
        icon: Icons.wifi_off_rounded,
        message: 'Data belum berhasil dimuat.',
        actionLabel: 'Coba Lagi',
        onAction: () => ref.invalidate(nearbyKoperasiProvider),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          // Daftarnya tidak lagi disaring radius, jadi kosong di sini benar-
          // benar berarti belum ada Kopdes terdaftar — bukan "tidak ada yang
          // dekat". Menawarkan "perluas jarak" di keadaan ini menyuruh orang
          // mengubah hal yang tidak berpengaruh.
          return const _SectionMessage(
            icon: Icons.store_mall_directory_outlined,
            message: 'Belum ada Kopdes yang terdaftar di sistem.',
          );
        }

        return SizedBox(
          height: 226,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final koperasi = page.items[index];
              return KoperasiCard(
                koperasi: koperasi,
                onOpen: () => context.push('/koperasi/${koperasi.id}'),
                onDirections: () async {
                  final opened = await openDirections(
                    latitude: koperasi.latitude,
                    longitude: koperasi.longitude,
                    label: koperasi.name,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak ada aplikasi peta di perangkat.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: SizedBox(
        height: 226,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          itemCount: 2,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => Container(
            width: 268,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.card),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 84, borderRadius: 0),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 170, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 120, height: 11, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 150, height: 11, borderRadius: 4),
                      SizedBox(height: 14),
                      ShimmerBox(
                        width: double.infinity,
                        height: 34,
                        borderRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pesan kosong / error, dengan aksi lanjutan bila memang ada yang bisa
/// dilakukan pengguna. Keadaan "belum ada Kopdes terdaftar" tidak punya aksi:
/// tombol di situ hanya mengulang hal yang sama.
class _SectionMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.mutedSoft),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
