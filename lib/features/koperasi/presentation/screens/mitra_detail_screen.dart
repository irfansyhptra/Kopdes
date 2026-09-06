import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/directions.dart';
import '../../domain/koperasi.dart';
import '../providers/koperasi_provider.dart';
import '../widgets/koperasi_card.dart' show MetaLine;

class MitraDetailScreen extends ConsumerWidget {
  final String mitraId;

  const MitraDetailScreen({super.key, required this.mitraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mitraDetailProvider(mitraId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => ref.invalidate(mitraDetailProvider(mitraId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (mitra) => _DetailView(mitra: mitra),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Mitra mitra;

  const _DetailView({required this.mitra});

  @override
  Widget build(BuildContext context) {
    // Tombol petunjuk arah hanya muncul kalau koordinatnya memang ada —
    // mitra yang belum diisi lokasinya tidak menampilkan tombol yang mati.
    final hasCoordinates = mitra.latitude != null && mitra.longitude != null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 190,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: ProductImageLoader(
              imageUrl: mitra.photoUrl ?? '',
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
                        mitra.businessName,
                        style: AppTypography.titleLarge.copyWith(fontSize: 22),
                      ),
                    ),
                    AppleBadge(label: mitra.category.label),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                MetaLine(
                  rating: mitra.rating,
                  distanceLabel: mitra.distanceLabel,
                  isOpen: mitra.isOpen,
                ),
                if (mitra.rating.hasRating) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${mitra.rating.count} ulasan',
                    style: AppTypography.captionSmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.base),

                if (mitra.description.isNotEmpty)
                  Text(
                    mitra.description,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                  ),
                const SizedBox(height: AppSpacing.base),

                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: mitra.address.isEmpty ? 'Belum diisi' : mitra.address,
                ),
                if (mitra.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Kontak',
                    value: mitra.phone!,
                  ),

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (hasCoordinates)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => openDirections(
                            latitude: mitra.latitude!,
                            longitude: mitra.longitude!,
                            label: mitra.businessName,
                          ),
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Petunjuk Arah'),
                        ),
                      ),
                    if (hasCoordinates && mitra.phone != null)
                      const SizedBox(width: AppSpacing.md),
                    if (mitra.phone != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              launchUrl(Uri.parse('tel:${mitra.phone}')),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('Hubungi'),
                        ),
                      ),
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
