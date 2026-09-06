import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../admin/presentation/widgets/admin_ui.dart';
import '../../data/superadmin_models.dart';
import '../providers/superadmin_providers.dart';

// Direktori seluruh pengguna terdaftar, dapat difilter per peran.
class UserDirectoryScreen extends ConsumerWidget {
  const UserDirectoryScreen({super.key});

  static const _filters = <String, String?>{
    'Semua': null,
    'Pelanggan': 'CUSTOMER',
    'Mitra UMKM': 'UMKM',
    'Kurir': 'COURIER',
    'Admin': 'ADMIN_KOPDES',
    'Pegawai': 'PEGAWAI_KOPDES',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final active = ref.watch(userRoleFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: adminAppBar(context, 'Direktori Pengguna'),
      body: Column(
        children: [
          Container(
            height: 52,
            color: AppColors.canvas,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              children: _filters.entries.map((e) {
                final selected = active == e.value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(e.key),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(userRoleFilterProvider.notifier).state =
                            e.value,
                    labelStyle: AppTypography.captionSmall.copyWith(
                      color: selected ? AppColors.onPrimary : AppColors.body,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(color: AppColors.hairlineSoft),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: AdminAsyncList<AppUser>(
              value: users,
              onRefresh: () => ref.invalidate(usersProvider),
              emptyTitle: 'Tidak ada pengguna pada kategori ini.',
              emptyIcon: Icons.person_search_outlined,
              itemBuilder: (u) => AdminCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceSoft,
                      child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(u.email, style: AppTypography.captionSmall),
                          if (u.phone.isNotEmpty)
                            Text(
                              u.phone,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.mutedSoft,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: roleLabel(u.role),
                      color: _roleColor(u.role),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
      case 'ADMIN_KOPDES':
        return AppColors.primary;
      case 'PEGAWAI_KOPDES':
        return AppColors.primaryActive;
      case 'UMKM':
        return AppColors.success;
      case 'COURIER':
        return AppColors.warning;
      default:
        return AppColors.muted;
    }
  }
}
