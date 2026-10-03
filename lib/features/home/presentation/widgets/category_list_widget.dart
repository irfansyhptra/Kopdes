import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/category_image_card.dart';

/// Kategori beranda dalam kartu foto ringkas dengan label overlay.
class CategoryListWidget extends StatelessWidget {
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onSeeAllTap;
  final String? selectedCategory;

  const CategoryListWidget({
    super.key,
    required this.onCategoryTap,
    required this.onSeeAllTap,
    this.selectedCategory,
  });

  static const List<String> _categories = [
    'Sembako',
    'Minuman',
    'Makanan Instan',
    'Perawatan',
    'Kosmetik',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: 'Kategori',
          actionLabel: 'Semua',
          onAction: onSeeAllTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Grid, bukan rail. Di beranda kategori adalah peta isi toko, dan
        // yang tersembunyi di luar layar praktis tidak pernah dibuka —
        // alasan yang sama dengan `.catgrid` di web.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // Padanan `minmax(96px, 1fr)`: tiga kolom di ponsel, lebih
              // banyak begitu layarnya melebar, tanpa breakpoint sendiri.
              maxCrossAxisExtent: 120,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 106,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryImageCard(
                width: double.infinity,
                height: 106,
                borderRadius: AppleRadii.tile,
                labelPadding: const EdgeInsets.all(AppSpacing.sm + 2),
                fontSize: 11.5,
                imageAsset: categoryImageAsset(category),
                label: category,
                selected: selectedCategory == category,
                onTap: () => onCategoryTap(category),
              );
            },
          ),
        ),
      ],
    );
  }
}
