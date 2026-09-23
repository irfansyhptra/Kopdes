import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/marketplace.dart';
import '../providers/marketplace_provider.dart';

/// Modal filter lanjutan.
///
/// Perubahan hanya diterapkan saat "Terapkan Filter" ditekan, sehingga menggeser
/// rentang harga tidak memicu satu permintaan jaringan per geseran.
Future<void> showMarketplaceFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.group),
      ),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late MarketplaceFilter _draft = ref.read(marketplaceFilterProvider);

  static const _priceSteps = <(String, double?, double?)>[
    ('Semua harga', null, null),
    ('< Rp25.000', null, 25000),
    ('Rp25.000 – Rp75.000', 25000, 75000),
    ('> Rp75.000', 75000, null),
  ];

  /// `null` = memakai bawaan server, bukan "tanpa batas": server selalu
  /// menerapkan radius maksimumnya sendiri.
  /// 0 berarti tanpa batas bawah — bukan "rating nol", yang justru akan
  /// menyaring habis seluruh katalog.
  static const _ratingSteps = <(String, double)>[
    ('Semua', 0),
    ('4,0+', 4),
    ('4,5+', 4.5),
  ];

  static const _radiusSteps = <(String, double?)>[
    ('Bawaan', null),
    ('3 km', 3),
    ('10 km', 10),
    ('25 km', 25),
  ];

  bool _priceSelected(double? min, double? max) =>
      _draft.minPrice == min && _draft.maxPrice == max;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Filter Produk',
                style: AppTypography.titleMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Rentang Harga'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (label, min, max) in _priceSteps)
                    AppleChip(
                      label: label,
                      selected: _priceSelected(min, max),
                      onTap: () => setState(() {
                        _draft = min == null && max == null
                            ? _draft.copyWith(clearPrice: true)
                            : _draft.copyWith(minPrice: min, maxPrice: max);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Sumber Produk'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final type in [
                    SellerType.all,
                    SellerType.kopdes,
                    SellerType.umkm,
                  ])
                    AppleChip(
                      label: type.label,
                      selected: _draft.sellerType == type,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(sellerType: type),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Urutkan'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (label, sort) in const [
                    ('Terbaru', MarketplaceSort.newest),
                    ('Harga termurah', MarketplaceSort.priceAsc),
                    ('Harga tertinggi', MarketplaceSort.priceDesc),
                  ])
                    AppleChip(
                      label: label,
                      selected: _draft.sort == sort,
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(sort: sort)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Rating Minimum'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (label, value) in _ratingSteps)
                    AppleChip(
                      label: label,
                      selected: _draft.minRating == value,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(minRating: value),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Produk yang belum punya ulasan ikut tersaring keluar saat '
                  'rating minimum dipakai.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Radius Pencarian'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (label, km) in _radiusSteps)
                    AppleChip(
                      label: label,
                      selected: _draft.radiusKm == km,
                      onTap: () => setState(() {
                        _draft = km == null
                            ? _draft.copyWith(clearRadius: true)
                            : _draft.copyWith(radiusKm: km);
                      }),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Radius berlaku pada pilihan "Terdekat", yang membutuhkan '
                  'lokasi Anda.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.inStockOnly,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(inStockOnly: v)),
                activeThumbColor: AppColors.primary,
                title: Text(
                  'Hanya produk tersedia',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.discountedOnly,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(discountedOnly: v)),
                activeThumbColor: AppColors.primary,
                title: Text(
                  'Hanya produk diskon',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                ),
                subtitle: const Text(
                  'Harga coret hanya ada pada produk Kopdes, jadi produk '
                  'mitra tidak ikut tampil.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _draft = const MarketplaceFilter()),
                      child: const Text('Atur Ulang'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Pencarian dipertahankan: modal ini tidak mengelola
                        // kolom pencarian, jadi tidak boleh menghapusnya.
                        ref
                            .read(marketplaceFilterProvider.notifier)
                            .state = _draft.copyWith(
                          search: ref.read(marketplaceFilterProvider).search,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
  );
}
