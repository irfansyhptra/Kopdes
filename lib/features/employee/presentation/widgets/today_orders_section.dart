import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/employee_dashboard.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Tiga pesanan prioritas hari ini dalam satu grouped surface.
class TodayOrdersSection extends ConsumerWidget {
  const TodayOrdersSection({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(todayOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KopdesSectionHeader(
          title: 'Pesanan Hari Ini',
          actionLabel: 'Lihat Semua',
          onAction: () => context.push('/pegawai/pesanan'),
        ),
        const SizedBox(height: KopdesSpacing.md),
        orders.when(
          loading: () => const _OrdersSkeleton(),
          error: (_, _) => KopdesSectionError(
            message: 'Pesanan belum berhasil dimuat',
            onRetry: () => ref.invalidate(todayOrdersProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KopdesSurface(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: KopdesSpacing.base),
                  child: Center(
                    child: Text(
                      'Belum ada pesanan hari ini',
                      style: TextStyle(
                        fontSize: 14,
                        color: KopdesEmployeeColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }
            return KopdesSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: KopdesSpacing.base,
                        endIndent: KopdesSpacing.base,
                        color: KopdesEmployeeColors.divider,
                      ),
                    _OrderRow(order: list[i], compact: compact),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order, required this.compact});

  final TodayOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      processingOrdersProvider.select((s) => s.contains(order.id)),
    );
    final canProcess = ref.watch(
      hasPermissionProvider(Permissions.orderProcess),
    );
    final action = order.action;

    final button = action == null
        ? const SizedBox.shrink()
        : _ActionButton(
            label: action.label,
            busy: busy,
            enabled: action.nextStatus == null || canProcess,
            onPressed: () => _run(context, ref, action),
          );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '#${order.reference}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KopdesEmployeeColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: KopdesSpacing.sm),
            Text(
              order.timeLabel,
              style: const TextStyle(
                fontSize: 11,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          order.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: KopdesEmployeeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: KopdesSpacing.sm,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${order.itemCount} produk',
              style: const TextStyle(
                fontSize: 12,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
            Text(
              order.total.formatted,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KopdesEmployeeColors.textPrimary,
              ),
            ),
            _StatusChip(status: order.status),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(KopdesSpacing.base),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Diukur, bukan hanya ditebak dari breakpoint halaman: tombol
          // "Siapkan Barang" butuh ruangnya sendiri, dan di bawah 400 dp
          // memaksanya sebaris akan menyisakan dua karakter untuk nama
          // pembeli. Kartu ini juga bisa muncul di kolom sempit pada tablet.
          final stacked = compact || constraints.maxWidth < 400;
          return _layout(
            stacked: stacked,
            info: info,
            button: button,
            action: action,
          );
        },
      ),
    );
  }

  Widget _layout({
    required bool stacked,
    required Widget info,
    required Widget button,
    required OrderAction? action,
  }) {
    return stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(url: order.thumbnailUrl),
                  const SizedBox(width: KopdesSpacing.md),
                  Expanded(child: info),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: KopdesSpacing.md),
                button,
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Thumbnail(url: order.thumbnailUrl),
              const SizedBox(width: KopdesSpacing.md),
              Expanded(child: info),
              const SizedBox(width: KopdesSpacing.sm),
              button,
            ],
          );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    OrderAction action,
  ) async {
    if (action.nextStatus == null) {
      context.push(action.route ?? '/pegawai/pesanan');
      return;
    }
    final error = await ref
        .read(employeeActionsProvider)
        .advanceOrder(order.id, action.nextStatus!);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: url == null || url!.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF0F0F2),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: KopdesEmployeeColors.textSecondary,
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                // Gambar gagal muat tidak boleh menjatuhkan baris pesanan.
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF0F0F2),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 18,
                    color: KopdesEmployeeColors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EmployeeOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EmployeeOrderStatus.pending ||
      EmployeeOrderStatus.paid => KopdesEmployeeColors.primary,
      EmployeeOrderStatus.processing => KopdesEmployeeColors.warning,
      EmployeeOrderStatus.readyForDelivery => KopdesEmployeeColors.info,
      EmployeeOrderStatus.outForDelivery => KopdesEmployeeColors.purple,
      EmployeeOrderStatus.delivered ||
      EmployeeOrderStatus.completed => KopdesEmployeeColors.success,
      EmployeeOrderStatus.cancelled => KopdesEmployeeColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: KopdesEmployeeColors.tint(color),
        borderRadius: BorderRadius.circular(KopdesRadii.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      // Ketukan kedua saat permintaan pertama belum kembali akan mengirim
      // transisi status yang sama dua kali.
      onPressed: enabled && !busy ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: KopdesEmployeeColors.primary,
        disabledBackgroundColor: const Color(0xFFE3E3E6),
        padding: const EdgeInsets.symmetric(
          horizontal: KopdesSpacing.md,
          vertical: 10,
        ),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KopdesRadii.pill),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return KopdesSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: KopdesEmployeeColors.divider,
              ),
            const Padding(
              padding: EdgeInsets.all(KopdesSpacing.base),
              child: Row(
                children: [
                  KopdesSkeleton(height: 44, width: 44, radius: 10),
                  SizedBox(width: KopdesSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KopdesSkeleton(height: 13, width: 90),
                        SizedBox(height: 6),
                        KopdesSkeleton(height: 13, width: 130),
                        SizedBox(height: 6),
                        KopdesSkeleton(height: 12, width: 110),
                      ],
                    ),
                  ),
                  SizedBox(width: KopdesSpacing.sm),
                  KopdesSkeleton(height: 36, width: 76, radius: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
