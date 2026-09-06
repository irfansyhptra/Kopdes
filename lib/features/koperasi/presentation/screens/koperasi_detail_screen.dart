import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/directions.dart';
import '../../domain/koperasi.dart';
import '../providers/koperasi_provider.dart';
import '../widgets/koperasi_card.dart';

class KoperasiDetailScreen extends ConsumerWidget {
  final String koperasiId;

  const KoperasiDetailScreen({super.key, required this.koperasiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(koperasiDetailProvider(koperasiId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(koperasiDetailProvider(koperasiId)),
        ),
        data: (koperasi) => _DetailView(koperasi: koperasi),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Koperasi koperasi;

  const _DetailView({required this.koperasi});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: ProductImageLoader(
              imageUrl: koperasi.imageUrl ?? '',
              placeholderIconSize: 48,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        koperasi.name,
                        style: AppTypography.titleLarge.copyWith(fontSize: 22),
                      ),
                    ),
                    if (koperasi.isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                MetaLine(
                  rating: koperasi.rating,
                  distanceLabel: koperasi.distanceLabel,
                  isOpen: koperasi.isOpen,
                ),
                if (koperasi.rating.hasRating) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${koperasi.rating.count} ulasan',
                    style: AppTypography.captionSmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.base),

                if (koperasi.description != null)
                  Text(
                    koperasi.description!,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                  ),
                const SizedBox(height: AppSpacing.base),

                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value:
                      '${koperasi.address}\n'
                      '${koperasi.village}, ${koperasi.district}, '
                      '${koperasi.city}, ${koperasi.province}',
                ),
                if (koperasi.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Kontak',
                    value: koperasi.phone!,
                  ),
                if (koperasi.serviceCategories.isNotEmpty)
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Layanan',
                    value: koperasi.serviceCategories.join(' • '),
                  ),

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openDirections(
                          latitude: koperasi.latitude,
                          longitude: koperasi.longitude,
                          label: koperasi.name,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Petunjuk Arah'),
                      ),
                    ),
                    if (koperasi.phone != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              launchUrl(Uri.parse('tel:${koperasi.phone}')),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('Hubungi'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.captionSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Data belum berhasil dimuat.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
