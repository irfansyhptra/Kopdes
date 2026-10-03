import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/category_image_card.dart';
import '../../../location/domain/user_location.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../koperasi/presentation/providers/koperasi_provider.dart';
import '../../../koperasi/presentation/widgets/location_prompt.dart';
import '../../../product/domain/entities/category.dart';
import '../../domain/marketplace.dart';
import '../providers/marketplace_provider.dart';

/// Judul section ringkas untuk Marketplace.
class MarketplaceSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Isi tambahan di sisi kanan judul, mis. baris lokasi. Judul tetap
  /// mendapat prioritas ruang: pada layar sempit yang mengalah adalah isi
  /// tambahannya, bukan judul sectionnya.
  final Widget? trailing;

  const MarketplaceSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          // Expanded, bukan Flexible + Spacer: dengan Spacer judul hanya
          // kebagian separuh lebar dan "Rekomendasi Untukmu" pecah jadi tiga
          // baris. Di sini judul mendapat sisa ruang setelah isi kanan
          // mengukur dirinya sendiri, jadi ia baru membungkus kalau memang
          // tidak muat.
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (actionLabel != null && onAction != null)
            ApplePressable(
              onTap: onAction,
              pressedScale: 1.0,
              semanticLabel: '$actionLabel $title',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTypography.buttonSm.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu satu pilihan filter berbasis foto dengan label overlay.
///
/// Ukurannya ikut skala teks, bukan angka tetap dari rancangan: pada teks
/// 2,0x label dua baris tetap muat karena kartunya ikut tumbuh, dan barisnya
/// menggulir mendatar sehingga tidak ada yang terpotong di layar 320dp.
class FilterOptionCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterOptionCard({
    super.key,
    required this.imageAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Skala teks yang dibatasi — dipakai bersama oleh kartu dan baris
  /// induknya supaya tinggi keduanya tidak pernah berselisih.
  static double textScale(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.8);

  /// 80×88, dari 104×112.
  ///
  /// Dua baris filter ini duduk di atas katalog, bukan menjadi isinya —
  /// kartu sebesar itu memakan hampir sepertiga layar sebelum satu produk
  /// pun terlihat. Tumbuhnya terhadap skala teks ikut dikecilkan secara
  /// proporsional supaya perbandingannya tetap sama di skala besar.
  static double widthOf(BuildContext context) {
    final scale = textScale(context);
    return 80 + (14 * (scale - 1));
  }

  static double heightOf(BuildContext context) {
    final scale = textScale(context);
    return 88 + (30 * (scale - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scale = textScale(context);
    return CategoryImageCard(
      width: widthOf(context),
      height: heightOf(context),
      imageAsset: imageAsset,
      label: label,
      selected: selected,
      onTap: onTap,
      labelPadding: EdgeInsets.all(AppSpacing.sm * scale),
      fontSize: 10.5 * scale,
    );
  }
}

/// Satu baris filter kategori. Dipakai dua kali: Makanan dan Barang Ritel.
///
/// Kedua baris memakai widget yang sama tetapi state terpisah, sehingga
/// memilih di satu baris tidak pernah diam-diam mengubah pilihan di baris lain.
class CategoryFilterRow extends ConsumerWidget {
  final String title;
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CategoryFilterRow({
    super.key,
    required this.title,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarketplaceSectionHeader(title: title),
        // Jarak ikut mengecil bersama kartunya: celah 12 di atas kartu 88
        // terbaca jauh lebih longgar daripada celah yang sama di atas 112.
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: FilterOptionCard.heightOf(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterOptionCard(
                  imageAsset: categoryImageAsset('Semua'),
                  label: 'Semua',
                  selected: selectedId == null,
                  onTap: () => onSelected(null),
                );
              }
              final category = categories[index - 1];
              return FilterOptionCard(
                imageAsset: categoryImageAsset(category.name),
                label: category.name,
                selected: selectedId == category.id,
                // Menekan kategori yang sudah aktif melepasnya — cara
                // menghapus pilihan tanpa tombol tambahan.
                onTap: () =>
                    onSelected(selectedId == category.id ? null : category.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Segmented control "Pilih Tempat Belanja".
class ShoppingSourceSelector extends ConsumerWidget {
  const ShoppingSourceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(marketplaceFilterProvider);
    final selected = filter.isDistanceSort
        ? SellerType.nearest
        : filter.sellerType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MarketplaceSectionHeader(
          title: 'Pilih Tempat Belanja',
          trailing: MarketplaceLocationBar(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Pada layar sempit, empat segmen berdampingan membuat label
              // terpotong — di situ deretannya digulir mendatar.
              final fits = constraints.maxWidth >= 340;
              final segments = [
                for (final type in SellerType.values)
                  _SourceSegment(
                    type: type,
                    selected: selected == type,
                    expanded: fits,
                    onTap: () => _select(ref, type),
                  ),
              ];

              if (fits) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppleRadii.control),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(children: segments),
                );
              }

              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: segments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) => segments[i],
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            0,
          ),
          child: Text(
            'Pilih sumber produk: dari Kopdes (Koperasi Desa) atau '
            'Mitra UMKM lokal.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ),
        // Tanpa koordinat, baris ringkas di kepala section tidak cukup:
        // pengguna perlu tahu kenapa lokasi diminta sebelum mengizinkannya.
        if (ref.watch(userCoordinatesProvider) == null)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: LocationPrompt(),
          ),
      ],
    );
  }

  void _select(WidgetRef ref, SellerType type) {
    final notifier = ref.read(marketplaceFilterProvider.notifier);

    if (type == SellerType.nearest) {
      final hasLocation = ref.read(userCoordinatesProvider) != null;
      if (!hasLocation) {
        // Izin tidak diminta di sini secara diam-diam. Pengguna diberi
        // pilihan lebih dulu — dan filternya tidak berubah sampai koordinat
        // benar-benar ada, supaya server tidak menolak sort=distance.
        _askForLocation(ref);
        return;
      }
      notifier.state = ref
          .read(marketplaceFilterProvider)
          .copyWith(sellerType: SellerType.all, sort: MarketplaceSort.distance);
      return;
    }

    notifier.state = ref
        .read(marketplaceFilterProvider)
        .copyWith(sellerType: type, sort: MarketplaceSort.newest);
  }

  void _askForLocation(WidgetRef ref) {
    final status = ref.read(locationProvider).status;
    // Belum pernah diminta → minta sekali. Sudah ditolak → jangan minta lagi,
    // tawarkan pemilihan manual lewat LocationPrompt di bawah section.
    if (status == LocationStatus.initial) {
      ref.read(locationProvider.notifier).requestLocation();
    }
  }
}

class _SourceSegment extends StatelessWidget {
  final SellerType type;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SourceSegment({
    required this.type,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  IconData get _icon => switch (type) {
    SellerType.all => Icons.storefront_rounded,
    SellerType.kopdes => Icons.apartment_rounded,
    SellerType.umkm => Icons.store_mall_directory_rounded,
    SellerType.nearest => Icons.near_me_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final segment = ApplePressable(
      onTap: onTap,
      pressedScale: 0.97,
      selected: selected,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleRadii.control - 1),
          border: expanded
              ? null
              : Border.all(
                  color: selected ? AppColors.primary : AppColors.hairline,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon mendampingi teks, tidak menggantikannya: keempat pilihan
            // tetap bisa dibedakan tanpa mengenali ikonnya.
            Icon(
              _icon,
              size: 14,
              color: selected ? AppColors.onPrimary : AppColors.muted,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonSm.copyWith(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.onPrimary : AppColors.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return expanded ? Expanded(child: segment) : segment;
  }
}

/// Baris lokasi ringkas: pin, nama tempat, dan tombol "Ubah".
///
/// Duduk di kepala section "Pilih Tempat Belanja", bukan sebagai baris
/// tersendiri — lokasi adalah keterangan dari pilihan itu, dan menyatukannya
/// menghemat satu baris penuh pada layar ponsel.
class MarketplaceLocationBar extends ConsumerWidget {
  const MarketplaceLocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(userCoordinatesProvider);

    // Tanpa koordinat, ajakan lengkapnya ada di bawah selector; di sini
    // cukup pintasan pendek supaya kepala section tidak melebar.
    if (location == null) {
      return ApplePressable(
        onTap: () => showVillagePicker(context, ref),
        pressedScale: 1.0,
        semanticLabel: 'Pilih lokasi belanja',
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 15,
                color: AppColors.primary,
              ),
              SizedBox(width: 4),
              Text(
                'Pilih lokasi',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      // Nama desa bisa sepanjang apa pun; tanpa batas ini judul sectionlah
      // yang mengalah dan membungkus. Pada ponsel kecil batasnya lebih
      // ketat — di 320dp judul dan lokasi tidak muat berdampingan.
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width < 360 ? 118 : 170,
      ),
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              location.label ?? 'Lokasi Anda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          ApplePressable(
            onTap: () => showVillagePicker(context, ref),
            pressedScale: 1.0,
            semanticLabel: 'Ubah lokasi',
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
