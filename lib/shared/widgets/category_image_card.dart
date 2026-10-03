import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'apple_ui.dart';

const String _categoryAssetRoot = 'assets/images/categories';

/// Memilih foto kategori dari nama yang dikirim backend.
///
/// Pencocokan sengaja berbasis kata kunci karena kategori dapat ditambah atau
/// diubah admin tanpa perlu mengirim path aset ke aplikasi.
String categoryImageAsset(String name) {
  final normalized = name.toLowerCase().trim();

  if (normalized == 'semua' || normalized.contains('semua kategori')) {
    return '$_categoryAssetRoot/all.webp';
  }
  if (normalized.contains('siap saji') ||
      normalized.contains('instan') ||
      normalized.contains('makan') ||
      normalized.contains('kuliner')) {
    return '$_categoryAssetRoot/food.webp';
  }
  if (normalized.contains('cemilan') ||
      normalized.contains('ringan') ||
      normalized.contains('snack')) {
    return '$_categoryAssetRoot/snacks.webp';
  }
  if (normalized.contains('minum') || normalized.contains('kopi')) {
    return '$_categoryAssetRoot/drinks.webp';
  }
  if (normalized.contains('bahan pokok') || normalized.contains('sembako')) {
    return '$_categoryAssetRoot/staples.webp';
  }
  if (normalized.contains('rumah') || normalized.contains('peralatan')) {
    return '$_categoryAssetRoot/household.webp';
  }
  if (normalized.contains('kosmetik')) {
    return '$_categoryAssetRoot/cosmetics.webp';
  }
  if (normalized.contains('rawat')) {
    return '$_categoryAssetRoot/personal_care.webp';
  }
  if (normalized.contains('kesehatan') || normalized.contains('cantik')) {
    return '$_categoryAssetRoot/health_beauty.webp';
  }
  if (normalized.contains('pakaian') ||
      normalized.contains('fesyen') ||
      normalized.contains('fashion')) {
    return '$_categoryAssetRoot/clothing.webp';
  }
  if (normalized.contains('kerajinan')) {
    return '$_categoryAssetRoot/crafts.webp';
  }
  if (normalized.contains('tani') ||
      normalized.contains('sayur') ||
      normalized.contains('buah')) {
    return '$_categoryAssetRoot/produce.webp';
  }
  if (normalized.contains('ikan') ||
      normalized.contains('laut') ||
      normalized.contains('perikanan')) {
    return '$_categoryAssetRoot/fish.webp';
  }
  if (normalized.contains('elektronik')) {
    return '$_categoryAssetRoot/electronics.webp';
  }
  return '$_categoryAssetRoot/all.webp';
}

/// Kartu kategori berbasis foto dengan label yang tetap terbaca di atas
/// gradient. Border, lapisan warna, dan indikator bulat menandai pilihan aktif.
class CategoryImageCard extends StatelessWidget {
  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry labelPadding;
  final double fontSize;

  const CategoryImageCard({
    super.key,
    required this.label,
    required this.imageAsset,
    this.selected = false,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius = AppleRadii.control,
    this.labelPadding = const EdgeInsets.all(AppSpacing.md),
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.97,
      selected: selected,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppAnimation.fast,
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairlineSoft,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : AppElevation.hairline,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
              cacheWidth: 420,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: AppColors.surfaceSoft,
                child: Image.asset(
                  '$_categoryAssetRoot/all.webp',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  cacheWidth: 420,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : null,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.28, 1],
                  colors: [Color(0x05000000), Color(0xD9000000)],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: labelPadding,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    color: Colors.white,
                    fontSize: fontSize,
                    height: 1.16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
