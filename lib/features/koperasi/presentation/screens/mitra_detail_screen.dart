import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/directions.dart';
import '../../domain/koperasi.dart';
import '../providers/koperasi_provider.dart';
import '../providers/koperasi_store_provider.dart';
import '../widgets/koperasi_card.dart' show MetaLine;
import '../widgets/store_chat_button.dart';
import '../widgets/store_sections.dart';

/// Etalase satu Mitra UMKM.
///
/// Susunannya sama persis dengan etalase Kopdes, dan bagian pencarian, filter,
/// serta grid produknya memang widget yang sama ([StoreSearchField],
/// [StoreFilterRow], [StoreProductGrid]) — bukan salinan.
///
/// Yang berbeda hanya kepalanya: mitra tidak punya keanggotaan, jadi tempat
/// ajakan "jadi anggota" di halaman Kopdes diisi keterangan Kopdes yang
/// menaunginya — satu-satunya jalan mitra bisa berjualan di sini.
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
          child: AppleActivityIndicator(size: 36, color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(mitraDetailProvider(mitraId)),
        ),
        data: (mitra) => _StoreView(mitra: mitra),
      ),
    );
  }
}

class _StoreView extends ConsumerWidget {
  final Mitra mitra;

  const _StoreView({required this.mitra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = (id: mitra.id, isUmkm: true);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(mitraDetailProvider(mitra.id));
        ref.invalidate(storeProductsProvider(store));
      },
      child: CustomScrollView(
        slivers: [
          _StoreBanner(mitra: mitra),
          SliverToBoxAdapter(child: _Identity(mitra: mitra)),
          if ((mitra.kopdesName ?? '').isNotEmpty)
            SliverToBoxAdapter(child: _KopdesStrip(mitra: mitra)),
          SliverToBoxAdapter(child: _About(mitra: mitra)),
          SliverToBoxAdapter(child: StoreSearchField(store: store)),
          SliverToBoxAdapter(child: StoreFilterRow(store: store)),
          StoreProductGrid(store: store),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _StoreBanner extends StatelessWidget {
  final Mitra mitra;

  const _StoreBanner({required this.mitra});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      title: Text(
        mitra.businessName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceStrong,
              child: ProductImageLoader(
                imageUrl: mitra.photoUrl ?? '',
                placeholderIconSize: 44,
              ),
            ),
            // Gradien gelap di dua tepi: tanpa ini tombol kembali dan judul
            // hilang di atas foto yang kebetulan terang.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8C000000),
                    Color(0x00000000),
                    Color(0x66000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final Mitra mitra;

  const _Identity({required this.mitra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        0,
      ),
      child: AppleCard(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lencana kategori sebaris dengan nama, bukan dengan baris meta:
            // meta berisi rating, jarak, dan status buka sekaligus, dan
            // menyandingkannya dengan lencana meluber pada layar 390dp.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    mitra.businessName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.2,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CategoryChip(category: mitra.category),
              ],
            ),
            const SizedBox(height: 6),
            MetaLine(
              rating: mitra.rating,
              distanceLabel: mitra.distanceLabel,
              isOpen: mitra.isOpen,
            ),
            if (mitra.address.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.mutedSoft,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mitra.address,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if ((mitra.ownerUserId ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: StoreChatButton(
                  ownerUserId: mitra.ownerUserId,
                  storeName: mitra.businessName,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final MitraCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Text(
        category.label,
        style: AppTypography.captionSmall.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

/// Kopdes yang menaungi mitra ini.
///
/// Bukan hiasan: mitra hanya boleh berjualan setelah diverifikasi Kopdes
/// desanya, jadi menyebut penaungnya adalah keterangan asal-usul yang
/// menentukan kepercayaan pembeli.
class _KopdesStrip extends StatelessWidget {
  final Mitra mitra;

  const _KopdesStrip({required this.mitra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppleRadii.group),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 22,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mitra binaan ${mitra.kopdesName}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sudah diverifikasi pengurus koperasi desanya.',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12,
                      height: 1.35,
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

class _About extends StatelessWidget {
  final Mitra mitra;

  const _About({required this.mitra});

  @override
  Widget build(BuildContext context) {
    final phone = mitra.phone;
    final lat = mitra.latitude;
    final lng = mitra.longitude;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.base,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppleSectionHeader(
            title: 'Tentang Toko',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppleCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mitra.description.trim().isEmpty
                      ? 'Mitra ini belum menuliskan keterangan tokonya.'
                      : mitra.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    height: 1.55,
                    color: mitra.description.trim().isEmpty
                        ? AppColors.mutedSoft
                        : AppColors.body,
                  ),
                ),
                if (phone != null && phone.isNotEmpty || lat != null) ...[
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    children: [
                      if (lat != null && lng != null)
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.directions_rounded,
                            label: 'Petunjuk Arah',
                            onTap: () => openDirections(
                              latitude: lat,
                              longitude: lng,
                              label: mitra.businessName,
                            ),
                          ),
                        ),
                      if (phone != null && phone.isNotEmpty) ...[
                        if (lat != null) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.call_rounded,
                            label: 'Telepon',
                            onTap: () => launchUrl(Uri.parse('tel:$phone')),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            onTap: () => launchUrl(
                              Uri.parse('https://wa.me/${_waNumber(phone)}'),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// wa.me menolak tanda plus dan spasi, dan nomor Indonesia yang diketik
  /// pemilik toko biasanya diawali 0.
  String _waNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.primarySoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryText),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonSm.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
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
              'Data toko belum berhasil dimuat.',
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
