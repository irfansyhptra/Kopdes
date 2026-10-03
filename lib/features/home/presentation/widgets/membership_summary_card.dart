import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/membership_summary.dart';

/// Ringkasan keanggotaan: saldo, poin, status — lalu empat aksi cepat.
///
/// Permukaan putih dengan hairline dan bayangan sangat halus, tanpa blur.
/// Kartu ini menggulir bersama halaman, jadi `BackdropFilter` di sini berarti
/// blur dihitung ulang setiap frame tanpa menyampaikan kedalaman apa pun.
class MembershipSummaryCard extends StatelessWidget {
  final MembershipSummary summary;
  final VoidCallback onTopUpTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onCouponTap;
  final VoidCallback onDetailTap;

  const MembershipSummaryCard({
    super.key,
    this.summary = MembershipSummary.none,
    required this.onTopUpTap,
    required this.onHistoryTap,
    required this.onCouponTap,
    required this.onDetailTap,
  });

  /// Bukan anggota: saldonya memang tidak ada, bukan nol. "Rp0" terbaca
  /// seperti dompet kosong yang bisa diisi; "Bukan Anggota" menjelaskan
  /// kenapa tidak ada apa-apa di sana.
  String get _balanceLabel => summary.balance == null
      ? 'Bukan Anggota'
      : formatRupiah(summary.balance!);

  String get _pointsLabel => formatThousands(summary.points);

  /// Tanda pisah, bukan "Bronze": jenjang terendah pun menyiratkan sudah
  /// jadi anggota.
  String get _statusLabel => summary.tier?.label ?? '—';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.hairline,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider bertinggi tetap, bukan VerticalDivider di dalam
          // IntrinsicHeight — menghindari satu lintasan pengukuran intrinsik
          // hanya untuk dua garis setebal 1px.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.primary,
                  label: 'Saldo Anggota',
                  value: _balanceLabel,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.stars_rounded,
                  iconColor: AppColors.warning,
                  label: 'Poin Belanja',
                  value: _pointsLabel,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.yellowAccent,
                  label: 'Status',
                  value: _statusLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          QuickActionRow(
            onTopUpTap: onTopUpTap,
            onHistoryTap: onHistoryTap,
            onCouponTap: onCouponTap,
            onDetailTap: onDetailTap,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: AppColors.hairlineSoft,
    );
  }
}

/// Empat aksi cepat dalam satu baris.
///
/// Labelnya sengaja pendek — versi sebelumnya memakai "Top Up Saldo" dan
/// "Riwayat Transaksi" pada kolom selebar seperempat layar, jadi terpotong
/// jadi "Top Up Sal…".
class QuickActionRow extends StatelessWidget {
  final VoidCallback onTopUpTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onCouponTap;
  final VoidCallback onDetailTap;

  const QuickActionRow({
    super.key,
    required this.onTopUpTap,
    required this.onHistoryTap,
    required this.onCouponTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add_rounded,
            label: 'Top Up',
            semanticLabel: 'Top up saldo anggota',
            onTap: onTopUpTap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_rounded,
            label: 'Riwayat',
            semanticLabel: 'Riwayat transaksi',
            onTap: onHistoryTap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.confirmation_number_outlined,
            label: 'Kupon',
            semanticLabel: 'Kupon saya',
            onTap: onCouponTap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_outline_rounded,
            label: 'Detail',
            semanticLabel: 'Detail anggota',
            onTap: onDetailTap,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: semanticLabel,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppleRadii.control),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.body),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
