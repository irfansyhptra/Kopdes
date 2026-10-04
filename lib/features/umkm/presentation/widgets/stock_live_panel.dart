import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/stock_live_repository.dart';
import '../controllers/stock_live_controller.dart';

/// Baris ringkas "Aktivitas stok": pergerakan terakhir, termasuk dari kasir
/// POS. Menekannya membuka riwayat lengkap.
///
/// Menggantikan panel tinggi yang dulu menghabiskan sepertiga layar hanya
/// untuk berkata "belum ada pergerakan".
class StockActivityRow extends ConsumerWidget {
  const StockActivityRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(stockLiveProvider);
    final latest = live.movements.isEmpty ? null : live.movements.first;
    final summary = latest != null
        ? '${latest.productName} ${_signed(latest)}'
              '${latest.stockAfter != null ? ' · sisa ${latest.stockAfter}' : ''}'
        : live.error != null
        ? 'Pemantauan terputus'
        : live.connected
        ? 'Belum ada perubahan'
        : 'Menghubungkan…';

    return ApplePressable(
      onTap: () => showStockHistorySheet(context),
      pressedScale: 0.98,
      semanticLabel: 'Aktivitas stok: $summary. Buka riwayat pergerakan stok',
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              // Sebaris bila muat; di layar sempit atau teks besar
              // keterangannya turun ke bawah judul alih-alih terhimpit
              // jadi "Bel…".
              final stacked = constraints.maxWidth < 320 * scale;

              final label = Text(
                'Aktivitas stok',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              );
              final detail = Text(
                summary,
                maxLines: stacked ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: live.error != null
                      ? AppColors.errorText
                      : AppColors.muted,
                ),
              );
              final trailing = [
                if (live.lastUpdate != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _clock(latest?.createdAt ?? live.lastUpdate!),
                    style: AppTypography.captionSmall.copyWith(fontSize: 12),
                  ),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ];

              if (stacked) {
                return Row(
                  children: [
                    _LiveDot(connected: live.connected),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [label, detail],
                      ),
                    ),
                    ...trailing,
                  ],
                );
              }
              return Row(
                children: [
                  _LiveDot(connected: live.connected),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(flex: 2, child: label),
                  Container(
                    width: 1,
                    height: 18,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    color: AppColors.hairline,
                  ),
                  Expanded(flex: 3, child: detail),
                  ...trailing,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _clock(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}.${at.minute.toString().padLeft(2, '0')}';
}

String _signed(StockMovement m) => switch (m.type) {
  StockMovementType.keluar => '−${m.quantity}',
  StockMovementType.masuk => '+${m.quantity}',
  StockMovementType.koreksi => '±${m.quantity}',
};

/// Riwayat pergerakan stok yang ditahan pemantauan (terbaru di atas).
Future<void> showStockHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.card),
      ),
    ),
    builder: (_) => const _StockHistorySheet(),
  );
}

class _StockHistorySheet extends ConsumerWidget {
  const _StockHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(stockLiveProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.md,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _LiveDot(connected: live.connected),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Riwayat Pergerakan Stok',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Text(
              live.connected
                  ? 'Pergerakan dari aplikasi dan kasir POS, '
                        '${StockLiveNotifier.maxMovements} terakhir.'
                  : 'Pemantauan terputus. Daftar ini mungkin belum terbaru.',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12.5,
                color: live.connected ? AppColors.muted : AppColors.errorText,
              ),
            ),
          ),
          const Divider(height: AppSpacing.lg),
          Expanded(
            child: live.movements.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        live.connected
                            ? 'Belum ada perubahan stok yang tercatat.'
                            : 'Menunggu sambungan ke server…',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      0,
                      AppSpacing.base,
                      AppSpacing.xl,
                    ),
                    itemCount: live.movements.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: AppSpacing.lg),
                    itemBuilder: (_, i) =>
                        StockMovementRow(movement: live.movements[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  final bool connected;

  const _LiveDot({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: connected ? 'Pemantauan aktif' : 'Pemantauan terputus',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: connected ? AppColors.success : AppColors.mutedSoft,
        ),
      ),
    );
  }
}

class StockMovementRow extends StatelessWidget {
  final StockMovement movement;

  const StockMovementRow({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isOut = movement.type == StockMovementType.keluar;
    final tint = switch (movement.type) {
      StockMovementType.masuk => AppColors.successText,
      StockMovementType.keluar => AppColors.errorText,
      StockMovementType.koreksi => AppColors.warningText,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isOut
              ? Icons.arrow_downward_rounded
              : movement.type == StockMovementType.masuk
              ? Icons.arrow_upward_rounded
              : Icons.tune_rounded,
          size: 16,
          color: tint,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                movement.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(
                _detail(movement),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _signed(movement),
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: tint,
              ),
            ),
            if (movement.stockAfter != null)
              Text(
                'sisa ${movement.stockAfter}',
                style: AppTypography.captionSmall.copyWith(fontSize: 10.5),
              ),
          ],
        ),
      ],
    );
  }

  /// Asal pergerakan disebut lebih dulu: pemilik toko perlu tahu mana yang
  /// dari kasir dan mana yang ia catat sendiri.
  static String _detail(StockMovement m) {
    final parts = <String>[
      if (m.fromPos) 'Kasir · ${m.externalRef}' else m.reason ?? m.type.label,
      if (m.recordedBy != null) m.recordedBy!,
    ];
    return parts.join(' · ');
  }
}
