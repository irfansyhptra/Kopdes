import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/stock_live_repository.dart';
import '../controllers/stock_live_controller.dart';

/// Pergerakan stok yang sedang terjadi, termasuk dari kasir POS.
class StockLivePanel extends ConsumerWidget {
  const StockLivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(stockLiveProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.hairline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _LiveDot(connected: live.connected),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Pergerakan Stok Langsung',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (live.lastUpdate != null)
                Text(
                  _clock(live.lastUpdate!),
                  style: AppTypography.captionSmall.copyWith(fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (live.movements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                live.connected
                    ? 'Belum ada pergerakan sejak layar ini dibuka.'
                    : 'Menunggu sambungan ke server…',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            for (var i = 0; i < live.movements.length && i < 8; i++) ...[
              if (i > 0) const Divider(height: AppSpacing.base),
              _MovementRow(movement: live.movements[i]),
            ],

          // Kegagalan tidak mengosongkan daftar — ia hanya memberi tahu
          // bahwa angka di atas mungkin sudah tertinggal.
          if (live.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pemantauan terputus. Angka di atas mungkin belum terbaru.',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11.5,
                color: AppColors.errorText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _clock(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}.${at.minute.toString().padLeft(2, '0')}';
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

class _MovementRow extends StatelessWidget {
  final StockMovement movement;

  const _MovementRow({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isOut = movement.type == StockMovementType.keluar;
    final tint = switch (movement.type) {
      StockMovementType.masuk => AppColors.success,
      StockMovementType.keluar => AppColors.errorText,
      StockMovementType.koreksi => AppColors.warning,
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
              '${isOut ? '−' : '+'}${movement.quantity}',
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
