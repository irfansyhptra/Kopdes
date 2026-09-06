import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_page_provider.dart';
import 'cart_seller_group.dart';

/// Isi Ringkasan Belanja, dipakai baik oleh panel ponsel maupun kartu tablet.
class ShoppingSummaryBody extends ConsumerWidget {
  /// Terlipat hanya menampilkan total dan tombol checkout.
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback onCheckout;

  const ShoppingSummaryBody({
    super.key,
    required this.expanded,
    required this.onCheckout,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final allState = ref.watch(allItemsCheckStateProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(expanded: expanded, onToggle: onToggleExpanded),
        if (expanded) ...[
          const SizedBox(height: AppSpacing.md),
          _Line(
            label: 'Subtotal (${summary.selectedLines} produk)',
            value: formatRupiah(summary.subtotal),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Line(
            label: 'Ongkir',
            value: summary.shipping == 0
                ? 'Gratis'
                : formatRupiah(summary.shipping),
            valueColor: summary.shipping == 0 ? AppColors.success : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _Line(
            label: 'Diskon',
            value: summary.discount == 0
                ? '-'
                : '-${formatRupiah(summary.discount)}',
            valueColor: summary.discount == 0 ? null : AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.hairlineSoft),
        ],
        const SizedBox(height: AppSpacing.md),
        _SelectAllRow(state: allState, totalLines: summary.totalLines),
        const SizedBox(height: AppSpacing.md),
        _TotalAndCheckout(
          total: summary.total,
          count: summary.selectedLines,
          onCheckout: summary.canCheckout ? onCheckout : null,
        ),
      ],
    );
  }
}

/// Total dan tombol checkout.
///
/// Berdampingan selama muat; pada layar sempit atau teks yang diperbesar
/// keduanya menumpuk — memaksa keduanya sebaris membuat tombolnya terpotong,
/// dan tombol checkout yang labelnya terpotong adalah tombol yang menakutkan.
class _TotalAndCheckout extends StatelessWidget {
  final int total;
  final int count;
  final VoidCallback? onCheckout;

  const _TotalAndCheckout({
    required this.total,
    required this.count,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    // Label lebih dulu, lalu nominalnya — pembaca layar membacanya dalam
    // urutan itu juga.
    final totalBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Pembayaran',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
        ),
        Text(
          formatRupiah(total),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.primary,
          ),
        ),
      ],
    );

    final button = _CheckoutButton(count: count, onTap: onCheckout);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stacked = constraints.maxWidth < 300 || textScale > 1.3;

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              totalBlock,
              const SizedBox(height: AppSpacing.md),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: totalBlock),
            const SizedBox(width: AppSpacing.md),
            button,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool expanded;
  final VoidCallback? onToggle;

  const _Header({required this.expanded, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Ringkasan Belanja',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.titleMedium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );

    if (onToggle == null) return title;

    return ApplePressable(
      onTap: onToggle,
      pressedScale: 1.0,
      semanticLabel: expanded
          ? 'Lipat Ringkasan Belanja'
          : 'Buka Ringkasan Belanja',
      child: Row(
        children: [
          Expanded(child: title),
          Icon(
            expanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: AppColors.mutedSoft,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Line({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          maxLines: 1,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SelectAllRow extends ConsumerWidget {
  final CheckState state;
  final int totalLines;

  const _SelectAllRow({required this.state, required this.totalLines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TriStateCheckbox(
          state: state,
          semanticLabel: 'Pilih semua produk di keranjang',
          onTap: () {
            final notifier = ref.read(selectedCartItemsProvider.notifier);
            if (state == CheckState.all) {
              notifier.clearSelection();
            } else {
              final cart = ref.read(cartProvider).valueOrNull;
              notifier.selectAll(cart?.items.map((i) => i.id) ?? const []);
            }
          },
        ),
        Expanded(
          child: Text(
            'Pilih Semua ($totalLines produk)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _CheckoutButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: enabled
          ? 'Checkout $count produk'
          : 'Checkout, belum ada produk dipilih',
      child: Container(
        // Tinggi minimum, bukan tetap: pada teks besar tombol boleh tumbuh
        // daripada memotong labelnya.
        constraints: const BoxConstraints(minHeight: 46, minWidth: 132),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : AppColors.hairlineSoft,
          borderRadius: BorderRadius.circular(AppleRadii.tile - 3),
        ),
        child: Text(
          'Checkout ($count)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.buttonSm.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.onPrimary : AppColors.mutedSoft,
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkasan untuk kolom kanan pada tablet.
class ShoppingSummaryCard extends StatelessWidget {
  final VoidCallback onCheckout;

  const ShoppingSummaryCard({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      radius: AppleRadii.group,
      padding: const EdgeInsets.all(AppSpacing.base),
      clip: false,
      // Di tablet ringkasan selalu terbuka: kolomnya memang disediakan
      // untuk itu, jadi tidak ada gunanya melipatnya.
      child: ShoppingSummaryBody(expanded: true, onCheckout: onCheckout),
    );
  }
}

/// Panel ringkasan mengambang untuk ponsel.
///
/// Bukan `Scaffold.bottomSheet`: Scaffold-nya milik [AppShell] yang juga
/// memasang bilah navigasi, dan keduanya akan bertabrakan. Panel ini
/// diposisikan sendiri tepat di atas bilah itu.
class ShoppingSummaryPanel extends ConsumerWidget {
  final VoidCallback onCheckout;

  const ShoppingSummaryPanel({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(summaryExpandedProvider);

    return AnimatedSize(
      duration: MediaQuery.maybeOf(context)?.disableAnimations ?? false
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.md,
          AppSpacing.base,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppleRadii.group),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ShoppingSummaryBody(
          expanded: expanded,
          onCheckout: onCheckout,
          onToggleExpanded: () =>
              ref.read(summaryExpandedProvider.notifier).state = !expanded,
        ),
      ),
    );
  }
}
