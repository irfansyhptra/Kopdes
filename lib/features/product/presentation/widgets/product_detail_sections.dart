import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../order/data/review_repository.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/entities/product.dart';

/// Bagian-bagian halaman detail produk.
///
/// Dipisah dari layarnya supaya berkas layar tetap terbaca sebagai susunan,
/// bukan sebagai seribu baris widget.

// ─────────────────────────────────────────────────────────────
// Harga, terjual, rating
// ─────────────────────────────────────────────────────────────

class ProductHeadline extends StatelessWidget {
  final Product product;

  const ProductHeadline({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                rupiah.format(product.effectivePrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.1,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  rupiah.format(product.price),
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.mutedSoft,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    '-${product.discountPercent}%',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (product.hasRating) ...[
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: AppColors.yellowAccent,
              ),
              const SizedBox(width: 3),
              Text(
                '${product.ratingLabel} (${product.ratingCount})',
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const _Dot(),
            ],
            // Nol tidak ditulis: "0 terjual" pada barang baru terbaca sebagai
            // barang yang tidak laku, padahal ia belum sempat dijual.
            if (product.soldCount > 0) ...[
              Text(
                '${product.soldCount} terjual',
                style: AppTypography.captionSmall.copyWith(fontSize: 12.5),
              ),
              const _Dot(),
            ],
            Flexible(
              child: Text(
                product.stock > 0
                    ? 'Stok ${product.stock} ${product.unit}'
                    : 'Stok habis',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12.5,
                  color: product.stock > 0 ? AppColors.muted : AppColors.error,
                  fontWeight: product.stock > 0
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          product.name,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.3,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: AppTypography.captionSmall.copyWith(color: AppColors.mutedSoft),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Foto produk
// ─────────────────────────────────────────────────────────────

/// Deretan foto produk sebagai kartu kecil.
///
/// Ini galeri foto, bukan varian jual: backend tidak punya model varian —
/// tidak ada SKU per ukuran atau warna — jadi menamainya "variasi" akan
/// menjanjikan pilihan yang tidak bisa dipesan.
class ProductPhotoStrip extends StatelessWidget {
  final List<ProductImage> images;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const ProductPhotoStrip({
    super.key,
    required this.images,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (images.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppleSectionHeader(
          title: 'Foto Produk',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final selected = index == activeIndex;
              return ApplePressable(
                onTap: () => onSelect(index),
                semanticLabel: 'Foto ${index + 1}',
                borderRadius: BorderRadius.circular(AppleRadii.control),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppleRadii.control),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.hairlineSoft,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppleRadii.control - 2),
                    child: ColoredBox(
                      color: AppColors.surfaceSoft,
                      child: ProductImageLoader(
                        imageUrl: images[index].url,
                        placeholderIconSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pengiriman
// ─────────────────────────────────────────────────────────────

/// Dua cara menerima barang yang memang didukung sistem.
///
/// Keterangan, bukan pilihan: keduanya dipilih saat checkout bersama alamat
/// dan pembayaran. Menaruh pilihannya di sini berarti menyimpan keputusan yang
/// belum punya tempat menyimpannya.
class ShippingOptions extends StatelessWidget {
  const ShippingOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppleSectionHeader(
          title: 'Pilihan Pengiriman',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppleListGroup(
          indent: 56,
          children: const [
            _ShippingRow(
              icon: Icons.storefront_rounded,
              title: 'Ambil di Tempat',
              body: 'Barang disiapkan, kamu ambil tanpa antre.',
            ),
            _ShippingRow(
              icon: Icons.delivery_dining_rounded,
              title: 'Diantar Kurir Desa',
              body: 'Diantar ke alamatmu; ongkirnya dihitung saat checkout.',
            ),
          ],
        ),
      ],
    );
  }
}

class _ShippingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ShippingRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryText),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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
// Ulasan
// ─────────────────────────────────────────────────────────────

/// Penilaian dan ulasan sebuah produk.
///
/// Menerima [target], bukan entitas produk: barang Kopdes dan barang mitra
/// UMKM adalah dua tabel berbeda dengan dua parameter berbeda di endpoint
/// ulasan, tetapi tampilannya satu dan sama. Sebelumnya tiap halaman punya
/// penyedia dan modelnya sendiri untuk endpoint yang sama persis.
class ProductReviewSection extends ConsumerWidget {
  final ReviewTarget target;
  final double? ratingAverage;
  final int ratingCount;

  const ProductReviewSection({
    super.key,
    required this.target,
    required this.ratingAverage,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productReviewsProvider(target));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppleSectionHeader(
          title: 'Penilaian Produk',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        _RatingSummary(average: ratingAverage, count: ratingCount),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: AppleActivityIndicator(size: 22)),
          ),
          error: (_, __) => const _NoReviews(
            icon: Icons.cloud_off_rounded,
            title: 'Ulasan belum berhasil dimuat',
            message: 'Periksa koneksi lalu tarik halaman untuk memuat ulang.',
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const _NoReviews(
                icon: Icons.rate_review_outlined,
                title: 'Belum ada ulasan',
                message:
                    'Jadilah yang pertama menilai setelah pesanan Anda '
                    'sampai.',
              );
            }
            return AppleListGroup(
              indent: 0,
              children: [
                for (final review in page.items) _ReviewRow(review: review),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Ringkasan penilaian: angka besar, bintang, dan banyaknya penilai.
///
/// Angkanya didahulukan karena itu yang dicari pembeli sekilas; bintang
/// mengulanginya dalam bentuk yang bisa dipindai tanpa membaca, dan jumlah
/// penilai memberi tahu seberapa jauh angka itu layak dipercaya — 5,0 dari
/// satu orang bukan hal yang sama dengan 4,6 dari dua ratus orang.
class _RatingSummary extends StatelessWidget {
  final double? average;
  final int count;

  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    final average = this.average;
    final hasRating = average != null && count > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Text(
            // Selalu satu desimal, dalam rentang 1,0–5,0. Tanpa penilaian
            // yang ditampilkan garis, bukan "0,0" — nol bukan nilai yang
            // pernah bisa diberikan siapa pun.
            hasRating ? average.toStringAsFixed(1).replaceAll('.', ',') : '—',
            style: AppTypography.displayMedium.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: AppColors.ink,
              height: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Stars(value: hasRating ? average : 0),
                const SizedBox(height: 4),
                Text(
                  hasRating
                      ? '$count orang memberi penilaian'
                      : 'Belum ada yang menilai',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lima bintang, terisi mengikuti nilainya.
class _Stars extends StatelessWidget {
  final double value;

  const _Stars({required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Koma, sama dengan yang tertulis di layar: pembaca layar dan mata
      // harus menyebut angka yang sama.
      label: value > 0
          ? 'Penilaian ${value.toStringAsFixed(1).replaceAll('.', ',')} dari 5'
          : 'Belum ada penilaian',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                // Setengah bintang dipakai supaya 4,5 tidak terbaca sama
                // dengan 4,0 maupun 5,0.
                value >= i
                    ? Icons.star_rounded
                    : value >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: value > 0
                    ? const Color(0xFFFFB800)
                    : AppColors.mutedSoft,
              ),
          ],
        ),
      ),
    );
  }
}

/// Keadaan kosong untuk ulasan — digambar, bukan sebaris teks abu-abu.
class _NoReviews extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NoReviews({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.card),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.mutedSoft),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final ProductReview review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bintang digambar utuh lima supaya nilainya terbaca tanpa
              // menghitung, bukan hanya angka di samping ikon.
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: i <= review.rating
                      ? AppColors.yellowAccent
                      : AppColors.hairline,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                shortDateId(review.createdAt),
                style: AppTypography.captionSmall.copyWith(fontSize: 11),
              ),
            ],
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.45,
                color: AppColors.body,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Toko
// ─────────────────────────────────────────────────────────────

class StoreCard extends StatelessWidget {
  final ProductStore store;
  final double? ratingAverage;
  final int ratingCount;

  /// Jarak dari pengguna, dihitung di layar dari koordinat toko dan posisi
  /// pengguna. Null bila salah satunya belum diketahui.
  final String? distanceLabel;

  const StoreCard({
    super.key,
    required this.store,
    this.ratingAverage,
    this.ratingCount = 0,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppleRadii.control),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ColoredBox(
                    color: AppColors.surfaceSoft,
                    child: ProductImageLoader(
                      imageUrl: store.logoUrl ?? store.imageUrl ?? '',
                      placeholderIconSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    if (store.shortAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        store.shortAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ApplePressable(
                onTap: () => context.push('/kopdes/${store.id}'),
                semanticLabel: 'Kunjungi ${store.name}',
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.primarySoft),
                  ),
                  child: Text(
                    'Kunjungi',
                    style: AppTypography.buttonSm.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.hairlineSoft,
            ),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(
                  label: 'Penilaian',
                  value: ratingCount > 0 && ratingAverage != null
                      ? ratingAverage!.toStringAsFixed(1).replaceAll('.', ',')
                      : '—',
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.hairlineSoft,
                ),
                _Stat(label: 'Jumlah Produk', value: '${store.productCount}'),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.hairlineSoft,
                ),
                _Stat(label: 'Jarak', value: distanceLabel ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
