import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/koperasi.dart';
import '../providers/koperasi_provider.dart';
import 'location_prompt.dart';
import 'mitra_card.dart';

/// Section "Mitra UMKM Terdekat" di beranda, lengkap dengan filter kategori.
class NearbyMitraSection extends ConsumerWidget {
  const NearbyMitraSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCoordinates = ref.watch(userCoordinatesProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: 'Mitra UMKM Terdekat',
          actionLabel: 'Lihat Semua',
          onAction: () => context.push('/umkm'),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _CategoryFilter(),
        const SizedBox(height: AppSpacing.md),
        if (!hasCoordinates) const LocationPrompt() else const _MitraList(),
      ],
    );
  }
}

/// Filter kategori. Dipisah agar perubahan filter tidak membangun ulang
/// judul section maupun daftar di atasnya.
class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mitraCategoryFilterProvider);

    // "Semua" diwakili null, bukan nilai enum tersendiri — supaya tidak perlu
    // dikirim sebagai parameter kategori ke server.
    final options = <(String, MitraCategory?)>[
      ('Semua', null),
      for (final c in MitraCategory.values)
        if (c != MitraCategory.lainnya) (c.label, c),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (label, value) = options[i];
          return AppleChip(
            label: label,
            selected: selected == value,
            onTap: () =>
                ref.read(mitraCategoryFilterProvider.notifier).state = value,
          );
        },
      ),
    );
  }
}

class _MitraList extends ConsumerWidget {
  const _MitraList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyMitraProvider);

    return async.when(
      loading: () => const _MitraSkeleton(),
      error: (_, __) => _SectionMessage(
        icon: Icons.wifi_off_rounded,
        message: 'Data belum berhasil dimuat.',
        actionLabel: 'Coba Lagi',
        onAction: () => ref.invalidate(nearbyMitraProvider),
      ),
      data: (page) {
        if (page == null || page.items.isEmpty) {
          return _SectionMessage(
            icon: Icons.storefront_outlined,
            message: 'Belum ada Mitra UMKM di sekitar lokasi Anda.',
            actionLabel: 'Pilih Lokasi',
            onAction: () => showVillagePicker(context, ref),
          );
        }

        return SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final mitra = page.items[index];
              return MitraCard(
                mitra: mitra,
                onVisit: () => context.push('/umkm/${mitra.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _MitraSkeleton extends StatelessWidget {
  const _MitraSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: SizedBox(
        height: 214,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => Container(
            width: 224,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.card),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 80, borderRadius: 0),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 110, height: 11, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 130, height: 11, borderRadius: 4),
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

class _SectionMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
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
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
