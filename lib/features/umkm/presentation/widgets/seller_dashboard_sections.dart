import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/models/seller_model.dart';

/// Permukaan putih satu section. Satu bentuk untuk semuanya supaya radius,
/// tepi, dan bayangannya tidak dihitung ulang — dan salah — di tiap bagian.
class SellerSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SellerSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.hairline,
      ),
      child: child,
    );
  }
}

/// Omzet hari ini dan bulan ini, dipisah garis tipis.
///
/// Omzet, BUKAN saldo yang bisa ditarik: uang pesanan belum tentu sudah
/// masuk dompet, dan menyamakan keduanya membuat pemilik toko merencanakan
/// pengeluaran dari angka yang belum ada di tangannya.
class SalesSummaryCard extends StatelessWidget {
  final SellerDashboardStats stats;

  const SalesSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SellerSection(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.base,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SalesCell(
                icon: Icons.bar_chart_rounded,
                label: 'Penjualan Hari Ini',
                amount: stats.todayEarnings,
                orders: stats.todayOrders,
              ),
            ),
            const _CellDivider(),
            Expanded(
              child: _SalesCell(
                icon: Icons.calendar_month_rounded,
                label: 'Bulan Ini',
                amount: stats.monthlyEarnings,
                orders: stats.monthlyOrders,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final int orders;

  const _SalesCell({
    required this.icon,
    required this.label,
    required this.amount,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${formatRupiah(amount)}, $orders transaksi',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundIcon(icon: icon, tint: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                Text(
                  '$orders transaksi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    color: AppColors.hairlineSoft,
  );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _RoundIcon({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppleRadii.control),
      ),
      child: Icon(icon, size: 19, color: tint),
    );
  }
}

/// Satu tindakan cepat.
class SellerQuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SellerQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Empat tindakan cepat dalam satu baris — dua baris bila tidak muat.
///
/// Lebarnya dari `LayoutBuilder`, bukan dari lebar layar: dasbor dibatasi
/// lebarnya di tablet, dan tindakan harus mengikuti kolom yang benar-benar
/// diberikan kepadanya.
class QuickActionsRow extends StatelessWidget {
  final List<SellerQuickAction> actions;

  const QuickActionsRow({super.key, required this.actions});

  /// Di bawah ini satu kolom terlalu sempit untuk label dua kata, dan
  /// deretannya dipecah jadi dua baris berisi dua.
  static const double _minColumn = 76;

  @override
  Widget build(BuildContext context) {
    return SellerSection(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final perRow = constraints.maxWidth / actions.length >= _minColumn
              ? actions.length
              : 2;

          final rows = <List<SellerQuickAction>>[];
          for (var i = 0; i < actions.length; i += perRow) {
            rows.add(actions.sublist(i, (i + perRow).clamp(0, actions.length)));
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0)
                  const Divider(height: 1, color: AppColors.hairlineSoft),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < rows[r].length; i++) ...[
                        if (i > 0) const _CellDivider(),
                        Expanded(child: _QuickActionTile(action: rows[r][i])),
                      ],
                      // Baris terakhir yang kurang isinya tetap sejajar
                      // dengan baris di atasnya, bukan melebar sendiri.
                      for (var i = rows[r].length; i < perRow; i++)
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final SellerQuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: action.onTap,
      pressedScale: 0.95,
      semanticLabel: action.label,
      borderRadius: BorderRadius.circular(AppleRadii.control),
      child: Padding(
        // Area sentuh tetap lega walau tampilannya ringkas — tinggi
        // minimumnya 64, jauh di atas batas 44pt.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundIcon(icon: action.icon, tint: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris "perlu perhatian".
class AttentionItem {
  final IconData icon;
  final Color tint;
  final String title;

  /// Keterangan saat angkanya nol. Dipisah supaya nol tidak pernah
  /// mendapat kalimat mendesak.
  final String calmMessage;
  final String urgentMessage;
  final int count;
  final VoidCallback onTap;

  const AttentionItem({
    required this.icon,
    required this.tint,
    required this.title,
    required this.calmMessage,
    required this.urgentMessage,
    required this.count,
    required this.onTap,
  });

  String get message => count > 0 ? urgentMessage : calmMessage;
}

class AttentionSection extends StatelessWidget {
  final List<AttentionItem> items;
  final VoidCallback? onSeeAll;

  const AttentionSection({super.key, required this.items, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SellerSection(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Perlu Perhatian',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  // Flexible + elipsis: pada skala teks besar "Lihat semua"
                  // selebar separuh layar mendorong judulnya keluar kartu.
                  Flexible(
                    child: TextButton(
                      onPressed: onSeeAll,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: Text(
                        'Lihat semua',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.buttonSm.copyWith(
                          fontSize: 13,
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.hairlineSoft),
            _AttentionRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final AttentionItem item;

  const _AttentionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: item.onTap,
      pressedScale: 0.98,
      semanticLabel: '${item.title}, ${item.count}. ${item.message}',
      borderRadius: BorderRadius.circular(AppleRadii.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            _RoundIcon(icon: item.icon, tint: item.tint),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${item.count}',
              maxLines: 1,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                // Nol bukan peringatan: angkanya ikut meredup, bukan
                // berteriak merah untuk mengabarkan tidak ada apa-apa.
                color: item.count > 0 ? AppColors.primaryText : AppColors.muted,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedSoft,
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu sel pada ringkasan toko.
class StoreSummaryCell {
  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String? note;

  const StoreSummaryCell({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    this.note,
  });
}

/// Grid 2×2 ringkas, dipisah garis tipis.
class StoreSummaryGrid extends StatelessWidget {
  final List<StoreSummaryCell> cells;

  const StoreSummaryGrid({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    final rows = <List<StoreSummaryCell>>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(cells.sublist(i, (i + 2).clamp(0, cells.length)));
    }

    return SellerSection(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ringkasan Toko',
            style: AppTypography.titleMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0)
              const Divider(
                height: AppSpacing.base,
                color: AppColors.hairlineSoft,
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) const _CellDivider(),
                    Expanded(child: _SummaryCell(cell: rows[r][i])),
                  ],
                  for (var i = rows[r].length; i < 2; i++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final StoreSummaryCell cell;

  const _SummaryCell({required this.cell});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${cell.label} ${cell.value}${cell.note == null ? '' : ', ${cell.note}'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundIcon(icon: cell.icon, tint: cell.tint),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cell.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(fontSize: 12),
                  ),
                  Text(
                    cell.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  if (cell.note != null)
                    Text(
                      cell.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.mutedSoft,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ajakan melengkapi toko.
///
/// [onTap] boleh null — dan memang null bila tujuannya belum ada. Baris
/// tanpa aksi digambar sebagai keterangan biasa, bukan tombol yang tidak
/// melakukan apa-apa saat ditekan.
class StoreTipsRow extends StatelessWidget {
  final String actionLabel;
  final VoidCallback? onTap;

  const StoreTipsRow({super.key, required this.actionLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        children: [
          _RoundIcon(
            icon: Icons.lightbulb_outline_rounded,
            tint: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tingkatkan toko Anda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Lengkapi profil, foto produk, dan jam buka agar lebih '
                  'mudah ditemukan pembeli.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                // Label aksi berdiri di bawah keterangannya, bukan di sisi
                // kanan: pada 320dp nama aksi sepanjang "Lengkapi Profil"
                // berebut lebar dengan keterangan dan meluber.
                if (onTap != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonSm.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.primaryText,
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: 'Tingkatkan toko Anda. $actionLabel',
      borderRadius: BorderRadius.circular(AppleRadii.card),
      child: content,
    );
  }
}
