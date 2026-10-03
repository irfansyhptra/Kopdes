import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../domain/directions.dart';
import '../../domain/koperasi.dart';
import '../../domain/membership.dart';
import '../providers/koperasi_provider.dart';
import '../providers/koperasi_store_provider.dart';
import '../widgets/koperasi_card.dart';
import '../widgets/store_chat_button.dart';
import '../widgets/store_sections.dart';

/// Etalase satu Kopdes — membukanya seperti berdiri di depan tokonya.
///
/// Urutannya mengikuti cara orang menilai sebuah toko: rupanya dulu (foto,
/// nama, apakah sedang buka), lalu ajakan menjadi anggota, lalu keterangan dan
/// cara menghubungi, lalu layanan yang disediakan, dan terakhir barang yang
/// dijual — yang justru paling banyak memakan ruang, jadi ia yang menggulir.
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
          child: AppleActivityIndicator(size: 36, color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(koperasiDetailProvider(koperasiId)),
        ),
        data: (koperasi) => _StoreView(koperasi: koperasi),
      ),
    );
  }
}

class _StoreView extends ConsumerWidget {
  final Koperasi koperasi;

  const _StoreView({required this.koperasi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = (id: koperasi.id, isUmkm: false);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(koperasiDetailProvider(koperasi.id));
        ref.invalidate(storeProductsProvider(store));
        ref.invalidate(storeMembershipProvider(koperasi.id));
      },
      child: CustomScrollView(
        slivers: [
          _StoreBanner(koperasi: koperasi),
          SliverToBoxAdapter(child: _Identity(koperasi: koperasi)),
          SliverToBoxAdapter(child: _MembershipBanner(koperasi: koperasi)),
          SliverToBoxAdapter(child: _About(koperasi: koperasi)),
          if (koperasi.serviceCategories.isNotEmpty)
            SliverToBoxAdapter(child: _Services(koperasi: koperasi)),
          SliverToBoxAdapter(child: StoreSearchField(store: store)),
          SliverToBoxAdapter(child: StoreFilterRow(store: store)),
          StoreProductGrid(store: store),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Banner
// ─────────────────────────────────────────────────────────────

class _StoreBanner extends StatelessWidget {
  final Koperasi koperasi;

  const _StoreBanner({required this.koperasi});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      title: Text(
        koperasi.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      // Judulnya baru muncul setelah bannernya menyusut; di atas foto ia
      // hanya menambah teks yang bertabrakan dengan gambar.
      forceMaterialTransparency: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceStrong,
              child: ProductImageLoader(
                imageUrl: koperasi.imageUrl ?? '',
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

// ─────────────────────────────────────────────────────────────
// Identitas
// ─────────────────────────────────────────────────────────────

class _Identity extends StatelessWidget {
  final Koperasi koperasi;

  const _Identity({required this.koperasi});

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppleRadii.control),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: ColoredBox(
                      color: AppColors.surfaceSoft,
                      child: ProductImageLoader(
                        imageUrl: koperasi.logoUrl ?? '',
                        placeholderIconSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              koperasi.name,
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
                          if (koperasi.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      MetaLine(
                        rating: koperasi.rating,
                        distanceLabel: koperasi.distanceLabel,
                        isOpen: koperasi.isOpen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _AddressLine(koperasi: koperasi),
            if ((koperasi.adminUserId ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: StoreChatButton(
                  ownerUserId: koperasi.adminUserId,
                  storeName: koperasi.name,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final Koperasi koperasi;

  const _AddressLine({required this.koperasi});

  @override
  Widget build(BuildContext context) {
    final full = [
      koperasi.address,
      koperasi.village,
      koperasi.district,
      koperasi.city,
    ].where((part) => part.isNotEmpty).join(', ');

    return Row(
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
            full.isEmpty ? 'Alamat belum diisi' : full,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ajakan jadi anggota
// ─────────────────────────────────────────────────────────────

/// Isinya mengikuti keanggotaan sungguhan, bukan iklan yang sama untuk semua.
///
/// Menawarkan "Gabung Sekarang" kepada orang yang pendaftarannya sedang
/// menunggu verifikasi membuatnya mendaftar dua kali, dan kepada anggota aktif
/// membuatnya mengira keanggotaannya hilang.
class _MembershipBanner extends ConsumerWidget {
  final Koperasi koperasi;

  const _MembershipBanner({required this.koperasi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(storeMembershipProvider(koperasi.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        0,
      ),
      child: membership.maybeWhen(
        data: (value) => _banner(context, value),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _banner(BuildContext context, Membership? membership) {
    if (membership?.isActive ?? false) {
      return _StatusStrip(
        icon: Icons.workspace_premium_rounded,
        tint: AppColors.success,
        title: 'Kamu anggota ${koperasi.name}',
        body: 'Nikmati harga dan layanan khusus anggota.',
      );
    }

    if (membership?.isPending ?? false) {
      return _StatusStrip(
        icon: Icons.hourglass_top_rounded,
        tint: AppColors.warning,
        title: 'Pendaftaran sedang diperiksa',
        body: 'Pengurus akan mengabari begitu keputusannya keluar.',
      );
    }

    final rejected = membership?.status == MembershipStatus.rejected;

    return _JoinBanner(
      koperasiId: koperasi.id,
      title: rejected ? 'Pendaftaranmu ditolak' : 'Jadi anggota koperasi desa',
      body: rejected
          ? (membership?.reviewNote?.isNotEmpty ?? false)
                ? membership!.reviewNote!
                : 'Kamu bisa memperbaiki datanya dan mendaftar lagi.'
          : 'Ikut memiliki ${koperasi.name}, dapat harga anggota, dan bagi '
                'hasil usaha desamu.',
      actionLabel: rejected ? 'Daftar Ulang' : 'Gabung Sekarang',
    );
  }
}

class _JoinBanner extends StatelessWidget {
  final String koperasiId;
  final String title;
  final String body;
  final String actionLabel;

  const _JoinBanner({
    required this.koperasiId,
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: () => context.push('/membership/register'),
      semanticLabel: actionLabel,
      borderRadius: BorderRadius.circular(AppleRadii.group),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkRed, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(AppleRadii.group),
          boxShadow: AppElevation.accent,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(AppleRadii.control),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                size: 22,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  const _StatusStrip({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppleRadii.group),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: tint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tentang & kontak
// ─────────────────────────────────────────────────────────────

class _About extends StatelessWidget {
  final Koperasi koperasi;

  const _About({required this.koperasi});

  @override
  Widget build(BuildContext context) {
    final description = koperasi.description;
    final phone = koperasi.phone;

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
                  (description == null || description.trim().isEmpty)
                      ? 'Kopdes ini belum menuliskan keterangan tokonya.'
                      : description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    height: 1.55,
                    color: description == null
                        ? AppColors.mutedSoft
                        : AppColors.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.directions_rounded,
                        label: 'Petunjuk Arah',
                        onTap: () => openDirections(
                          latitude: koperasi.latitude,
                          longitude: koperasi.longitude,
                          label: koperasi.name,
                        ),
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
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
            ),
          ),
        ],
      ),
    );
  }

  /// wa.me menolak tanda plus dan spasi, dan nomor Indonesia yang diketik
  /// pengurus biasanya diawali 0.
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

// ─────────────────────────────────────────────────────────────
// Layanan
// ─────────────────────────────────────────────────────────────

class _Services extends StatelessWidget {
  final Koperasi koperasi;

  const _Services({required this.koperasi});

  @override
  Widget build(BuildContext context) {
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
            title: 'Layanan Tersedia',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final service in koperasi.serviceCategories)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.hairlineSoft),
                    boxShadow: AppElevation.subtle,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
