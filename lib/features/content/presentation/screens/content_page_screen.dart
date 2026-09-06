import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/content_provider.dart';

/// Menampilkan halaman informasi apa pun berdasarkan slug-nya.
///
/// Satu layar untuk semua konten: menambah halaman baru cukup dengan menambah
/// baris di tabel `ContentPage`, tanpa menyentuh aplikasi.
class ContentPageScreen extends ConsumerWidget {
  final String slug;

  /// Judul sementara sebelum isinya termuat, agar app bar tidak kosong.
  final String fallbackTitle;

  const ContentPageScreen({
    super.key,
    required this.slug,
    this.fallbackTitle = 'Informasi',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contentPageProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(title: Text(async.valueOrNull?.title ?? fallbackTitle)),
      body: async.when(
        loading: () => const _ContentSkeleton(),
        // Halaman yang belum terbit dijawab 404 oleh backend. Itu bukan
        // kerusakan — informasinya memang belum disiapkan pengurus, dan
        // pesannya harus mengatakan begitu apa adanya.
        error: (_, __) => _Unavailable(
          onRetry: () => ref.invalidate(contentPageProvider(slug)),
        ),
        data: (page) => ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            if (page.subtitle != null) ...[
              Text(
                page.subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            for (final section in page.sections) ...[
              if (section.heading.isNotEmpty) ...[
                Text(
                  section.heading,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                section.body,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (page.footnote != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppleRadii.card),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        page.footnote!,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ContentSkeleton extends StatelessWidget {
  const _ContentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerGroup(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 200, height: 14, borderRadius: 4),
            SizedBox(height: AppSpacing.lg),
            ShimmerBox(width: 160, height: 16, borderRadius: 4),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 6),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 6),
            ShimmerBox(width: 220, height: 12, borderRadius: 4),
            SizedBox(height: AppSpacing.lg),
            ShimmerBox(width: 140, height: 16, borderRadius: 4),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 6),
            ShimmerBox(width: 190, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _Unavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.article_outlined,
              size: 36,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Informasi belum tersedia.',
              style: AppTypography.bodyLarge.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Silakan hubungi pengurus Kopdes untuk penjelasan resminya.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
