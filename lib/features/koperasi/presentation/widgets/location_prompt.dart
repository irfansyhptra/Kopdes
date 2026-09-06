import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../location/domain/user_location.dart';
import '../../../location/presentation/providers/location_provider.dart';

/// Ajakan mengaktifkan lokasi, dengan pesan dan tombol yang menyesuaikan
/// penyebabnya.
///
/// Setiap keadaan selalu menyediakan jalan keluar: pengguna yang menolak izin
/// tetap bisa memilih desa secara manual, sehingga daftar terdekat tidak
/// pernah menjadi jalan buntu.
class LocationPrompt extends ConsumerWidget {
  const LocationPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    final (
      String message,
      String actionLabel,
      VoidCallback action,
    ) = switch (state.status) {
      LocationStatus.serviceDisabled => (
        'Layanan lokasi perangkat sedang mati.',
        'Buka Pengaturan',
        notifier.openLocationSettings,
      ),
      LocationStatus.permissionPermanentlyDenied => (
        'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.',
        'Buka Pengaturan',
        notifier.openAppSettings,
      ),
      LocationStatus.permissionDenied => (
        'Lokasi belum aktif. Pilih lokasi secara manual untuk melihat '
            'Kopdes dan UMKM di sekitar Anda.',
        'Aktifkan Lokasi',
        notifier.requestLocation,
      ),
      LocationStatus.locationError => (
        state.errorMessage ?? 'Lokasi belum berhasil diambil.',
        'Coba Lagi',
        notifier.requestLocation,
      ),
      _ => (
        'Aktifkan lokasi untuk menemukan Kopdes dan UMKM terdekat.',
        'Aktifkan Lokasi',
        notifier.requestLocation,
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isBusy ? null : action,
                  child: Text(actionLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showVillagePicker(context, ref),
                  child: const Text('Pilih Lokasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pemilih desa manual — jalan keluar saat izin lokasi tidak diberikan.
Future<void> showVillagePicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.group),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.base),
            child: Text(
              'Pilih Lokasi Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, color: AppColors.hairlineSoft),
          for (final village in VillageOption.all)
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: Text(village.name),
              subtitle: Text('${village.district}, ${village.city}'),
              onTap: () {
                ref.read(locationProvider.notifier).setManualLocation(village);
                Navigator.pop(sheetContext);
              },
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}
