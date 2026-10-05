import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../delivery/presentation/widgets/delivery_map.dart';
import '../../../koperasi/presentation/providers/koperasi_provider.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_models.dart';
import '../../data/courier_tracking.dart';

/// Posisi kurir saat ini.
///
/// Titik dari siaran langsung lebih disukai — itu yang paling baru dan
/// paling sering diperbarui. Di luar pengantaran, dipakai lokasi perangkat
/// yang sudah dimiliki aplikasi, supaya jarak tetap bisa ditampilkan tanpa
/// menyalakan GPS lagi.
final courierPositionProvider = Provider<({double lat, double lng})?>((ref) {
  final live = ref.watch(courierTrackingProvider).lastPosition;
  if (live != null) return (lat: live.latitude, lng: live.longitude);
  final saved = ref.watch(userCoordinatesProvider);
  if (saved != null) return (lat: saved.latitude, lng: saved.longitude);
  return null;
});

StatusPill taskStagePill(TaskStage stage) => StatusPill(
  icon: stage.icon,
  label: stage.label,
  tint: stage.tint,
  text: stage.textTint,
);

/// Penanda uang yang harus ditagih. Bukan sekadar warna: salah menagih
/// pesanan yang sudah lunas tidak bisa diperbaiki setelah kurir pergi.
class CodBadge extends StatelessWidget {
  final double amount;
  const CodBadge({super.key, required this.amount});

  @override
  Widget build(BuildContext context) => StatusPill(
    icon: Icons.payments_rounded,
    label: 'Tagih ${formatRupiah(amount)}',
    tint: AppColors.warning,
    text: AppColors.warningText,
  );
}

/// Satu tugas dalam daftar.
///
/// Dipakai di tiga tempat sekaligus — tugas tersedia, tugas saya, dan log
/// pengiriman — dengan tombol yang berbeda. Isinya sama karena yang perlu
/// diketahui kurir juga sama: barangnya apa, ambil di mana, antar ke mana,
/// dan menagih berapa.
class CourierTaskCard extends ConsumerWidget {
  final CourierTask task;
  final VoidCallback onTap;

  /// Tombol utama di kaki kartu. Kosong untuk log pengiriman.
  final Widget? action;

  const CourierTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(courierPositionProvider);
    final dest = task.destination;
    final distance = (me != null && dest.hasPoint)
        ? straightLineDistance(me.lat, me.lng, dest.latitude!, dest.longitude!)
        : null;

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.99,
      child: StoreSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '#${task.shortCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '${task.itemCount} barang',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                taskStagePill(task.stage),
                if (task.isCod) CodBadge(amount: task.codAmount),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final p in task.pickups) ...[
              _Line(
                icon: p.isKopdes
                    ? Icons.store_mall_directory_outlined
                    : Icons.storefront_outlined,
                title: 'Ambil di ${p.name}',
                subtitle: p.address,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _Line(
              icon: Icons.location_on_outlined,
              title: 'Antar ke ${dest.recipientName}',
              subtitle: distance == null
                  ? dest.fullAddress
                  : '${dest.fullAddress} · $distance',
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Line({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: AppColors.muted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12.5,
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

/// Tombol utama kartu tugas, setinggi 48 dp supaya mudah ditekan di jalan.
class TaskActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const TaskActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),
  );
}

/// Kartu angka hari ini di kepala dasbor kurir.
class CourierSummaryCard extends StatelessWidget {
  final CourierSummary summary;
  const CourierSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return StoreSurface(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Cell(
                icon: Icons.task_alt_rounded,
                label: 'Diantar Hari Ini',
                value: '${summary.deliveredToday}',
                note: 'Total ${summary.deliveredTotal} antaran',
              ),
            ),
            const VerticalDivider(
              width: AppSpacing.base,
              thickness: 1,
              color: AppColors.hairlineSoft,
            ),
            Expanded(
              child: _Cell(
                icon: Icons.payments_outlined,
                label: 'COD Terkumpul',
                value: formatRupiah(summary.codCollectedToday),
                note: 'Setorkan ke Kopdes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String note;

  const _Cell({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.captionSmall.copyWith(
            fontSize: 11.5,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
