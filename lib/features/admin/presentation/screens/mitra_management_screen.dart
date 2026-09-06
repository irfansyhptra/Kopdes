import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../data/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_ui.dart';
import '../../../chat/presentation/chat_launcher.dart';

// Pengelolaan mitra UMKM: verifikasi penerimaan, tangguhkan, aktifkan.
class MitraManagementScreen extends ConsumerWidget {
  const MitraManagementScreen({super.key});

  static const _filters = <String, String?>{
    'Semua': null,
    'Menunggu': 'PENDING_VERIFICATION',
    'Aktif': 'ACTIVE',
    'Ditolak': 'REJECTED',
    'Ditangguhkan': 'SUSPENDED',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mitra = ref.watch(mitraListProvider);
    final action = ref.watch(adminActionProvider);
    final activeFilter = ref.watch(mitraStatusFilterProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: adminAppBar(context, 'Pengelolaan Mitra UMKM'),
          body: Column(
            children: [
              _FilterBar(active: activeFilter, filters: _filters, ref: ref),
              Expanded(
                child: AdminAsyncList<Mitra>(
                  value: mitra,
                  onRefresh: () => ref.invalidate(mitraListProvider),
                  emptyTitle: 'Belum ada pengajuan mitra pada kategori ini.',
                  emptyIcon: Icons.storefront_outlined,
                  itemBuilder: (m) => _MitraCard(mitra: m, ref: ref),
                ),
              ),
            ],
          ),
        ),
        ActionOverlay(visible: action is AsyncLoading),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? active;
  final Map<String, String?> filters;
  final WidgetRef ref;
  const _FilterBar({
    required this.active,
    required this.filters,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.canvas,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        children: filters.entries.map((e) {
          final selected = active == e.value;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(e.key),
              selected: selected,
              onSelected: (_) =>
                  ref.read(mitraStatusFilterProvider.notifier).state = e.value,
              labelStyle: AppTypography.captionSmall.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.body,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(color: AppColors.hairlineSoft),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

({Color color, String label}) _statusMeta(String status) {
  switch (status) {
    case 'ACTIVE':
      return (color: AppColors.success, label: 'Aktif');
    case 'REJECTED':
      return (color: AppColors.error, label: 'Ditolak');
    case 'SUSPENDED':
      return (color: AppColors.muted, label: 'Ditangguhkan');
    default:
      return (color: AppColors.warning, label: 'Menunggu Verifikasi');
  }
}

class _MitraCard extends StatelessWidget {
  final Mitra mitra;
  final WidgetRef ref;
  const _MitraCard({required this.mitra, required this.ref});

  Future<void> _verify(
    BuildContext context,
    String status, {
    String? reason,
  }) async {
    final ok = await ref
        .read(adminActionProvider.notifier)
        .verifyMitra(mitra.id, status, reason: reason);
    if (context.mounted) {
      showSnack(
        context,
        ok ? 'Status mitra diperbarui' : 'Gagal memperbarui',
        error: !ok,
      );
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    // Dibuang di finally: dialog ini bukan milik State mana pun.
    final controller = TextEditingController();
    final String? reason;
    try {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvas,
          title: Text(
            'Tolak Mitra',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Alasan penolakan (opsional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (reason != null && context.mounted) {
      await _verify(
        context,
        'REJECTED',
        reason: reason.isEmpty ? null : reason,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(mitra.status);
    return AdminCard(
      accentColor: meta.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: meta.color.withOpacity(0.25)),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: meta.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mitra.businessName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          mitra.ownerName,
                          style: AppTypography.captionSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            '${mitra.productCount} Produk',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: meta.label,
                color: meta.color,
                icon: mitra.status == 'ACTIVE'
                    ? Icons.verified_user_rounded
                    : (mitra.status == 'PENDING_VERIFICATION'
                          ? Icons.hourglass_top_rounded
                          : Icons.info_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                _infoRow(Icons.location_on_outlined, mitra.address),
                if (mitra.phone.isNotEmpty)
                  _infoRow(Icons.phone_outlined, mitra.phone),
                if (mitra.status == 'REJECTED' && mitra.rejectionReason != null)
                  _infoRow(
                    Icons.warning_amber_rounded,
                    'Alasan: ${mitra.rejectionReason}',
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.hairlineSoft, height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Chat Mitra',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => openChatWith(
                  context,
                  ref,
                  mitra.ownerId,
                  mitra.businessName,
                ),
              ),
              _actions(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.mutedSoft),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.captionSmall.copyWith(
                color: color ?? AppColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    switch (mitra.status) {
      case 'PENDING_VERIFICATION':
      case 'REJECTED':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mitra.status == 'PENDING_VERIFICATION')
              TextButton(
                onPressed: () => _confirmReject(context),
                child: Text(
                  'Tolak',
                  style: AppTypography.buttonSm.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Setujui Mitra'),
              onPressed: () => _verify(context, 'ACTIVE'),
            ),
          ],
        );
      case 'ACTIVE':
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            minimumSize: Size.zero,
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          icon: const Icon(Icons.pause_circle_outline, size: 14),
          label: const Text('Tangguhkan'),
          onPressed: () => _verify(context, 'SUSPENDED'),
        );
      case 'SUSPENDED':
      default:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            minimumSize: Size.zero,
          ),
          icon: const Icon(Icons.play_circle_outline, size: 14),
          label: const Text('Aktifkan Kembali'),
          onPressed: () => _verify(context, 'ACTIVE'),
        );
    }
  }
}
