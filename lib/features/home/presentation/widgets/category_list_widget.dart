import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Card menu kategori — deretan tile squircle bergaya ikon iOS.
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

  static const List<({String name, IconData icon})> _categories = [
    (name: 'Sembako', icon: Icons.rice_bowl_rounded),
    (name: 'Minuman', icon: Icons.local_cafe_rounded),
    (name: 'Makanan Instan', icon: Icons.ramen_dining_rounded),
    (name: 'Perawatan', icon: Icons.clean_hands_rounded),
    (name: 'Kosmetik', icon: Icons.face_retouching_natural_rounded),
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
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return AppleMenuTile(
                // Beranda memakai tile lebih ringkas daripada Marketplace
                // supaya lebih banyak bagian muat dalam satu viewport.
                size: 48,
                icon: cat.icon,
                label: cat.name,
                tint: AppleTints.at(index),
                selected: selectedCategory == cat.name,
                onTap: () => onCategoryTap(cat.name),
              );
            },
          ),
        ),
      ],
    );
  }
}
