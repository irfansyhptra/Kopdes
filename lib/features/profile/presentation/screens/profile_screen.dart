import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Profil Saya.
///
/// Susunannya mengikuti rancangan: kepala merah berisi identitas, kartu
/// ringkasan yang menindih tepi bawahnya, lalu empat bagian bertingkat —
/// Aktivitas Saya, Akun & Belanja, Pengaturan, Bantuan — dan keluar akun.
///
/// Angka yang tidak punya sumbernya tidak dikarang. Saldo, poin, dan kupon
/// tampil sebagai "—": hanya saldo yang punya endpoint (`/wallet`) dan
/// aplikasi belum memanggilnya; poin dan kupon belum ada modelnya sama sekali
/// di backend. Menulis "Rp250.000" di sini berarti halaman akun memberi tahu
/// orang bahwa ia punya uang yang tidak pernah ada.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String _version = 'KMP Mitra v1.0.0';

  /// Tinggi tindihan kartu ringkasan ke kepala merah.
  static const double _overlap = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _Header(user: user),
            // Seluruh isi digeser ke atas sekaligus, bukan hanya kartunya:
            // menindihkan satu elemen saja membuat yang di bawahnya bertabrakan.
            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Column(
                children: [
                  _SummaryCard(user: user),
                  const SizedBox(height: AppSpacing.lg),
                  _ActivitySection(),
                  const SizedBox(height: AppSpacing.lg),
                  _AccountSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _HelpSection(),
                  const SizedBox(height: AppSpacing.lg),
                  const _LogoutRow(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _version,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.mutedSoft,
                    ),
                  ),
                  // Ruang untuk bilah bawah mengambang, dikurangi tindihan
                  // di atas supaya kaki halaman tidak berlebihan.
                  SizedBox(height: AppSpacing.xxl + _overlap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kepala
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final User? user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        top + AppSpacing.md,
        AppSpacing.base,
        // Ruang untuk kartu yang menindih tepi bawahnya.
        AppSpacing.lg + ProfileScreen._overlap,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkRed, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profil Saya',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              _HeaderIcon(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi',
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderIcon(
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
                onTap: () => _soon(context, 'Pengaturan akun'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(name: user?.name),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RolePill(role: user?.role),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user?.name ?? 'Warga Desa',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Dua baris meta seperti rancangan. Yang kedua email,
                    // bukan nama desa: alamat tidak ada di entitas pengguna,
                    // dan "Desa Lamteh" pada rancangan ditulis tetap.
                    _MetaLine(icon: Icons.phone_rounded, text: user?.phone),
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: Icons.mail_outline_rounded,
                      text: user?.email,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _EditProfileButton(onTap: () => _soon(context, 'Ubah profil')),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: Icon(icon, color: AppColors.onPrimary, size: 20),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? name;

  const _Avatar({required this.name});

  /// Dua huruf pertama dari nama. Tidak ada unggahan foto profil di backend,
  /// jadi tidak ada gambar yang bisa ditampilkan.
  String get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (parts.isEmpty) return '·';
    return parts.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x33FFFFFF),
        border: Border.all(color: AppColors.onPrimary, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// Lencana peran akun.
///
/// Rancangan menulis "Anggota VIP"; tidak ada tingkatan keanggotaan di
/// backend — `KopdesMembership` hanya mengenal PENDING/ACTIVE/REJECTED — jadi
/// yang ditampilkan adalah peran akun yang memang diketahui.
class _RolePill extends StatelessWidget {
  final String? role;

  const _RolePill({required this.role});

  String get _label {
    switch (role) {
      case 'CUSTOMER':
        return 'Anggota';
      case 'UMKM':
        return 'Mitra UMKM';
      case 'COURIER':
        return 'Kurir Desa';
      case 'PEGAWAI_KOPDES':
        return 'Pegawai Kopdes';
      case 'ADMIN_KOPDES':
        return 'Pengurus Kopdes';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return 'Belum masuk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: AppColors.yellowAccent,
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String? text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final value = (text == null || text!.trim().isEmpty) ? '—' : text!;
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 13,
              color: const Color(0xE6FFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: 'Edit Profil',
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: double.infinity,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.onPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Edit Profil',
              style: AppTypography.buttonSm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kartu ringkasan
// ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final User? user;

  const _SummaryCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppleCard(
        clip: false,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: _SummaryStat(
                      icon: Icons.account_balance_wallet_rounded,
                      tint: AppColors.primary,
                      label: 'Saldo',
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 6,
                    endIndent: 6,
                    color: AppColors.hairlineSoft,
                  ),
                  const Expanded(
                    child: _SummaryStat(
                      icon: Icons.star_rounded,
                      tint: AppColors.warning,
                      label: 'Poin',
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 6,
                    endIndent: 6,
                    color: AppColors.hairlineSoft,
                  ),
                  const Expanded(
                    child: _SummaryStat(
                      icon: Icons.confirmation_number_rounded,
                      tint: AppColors.primary,
                      label: 'Kupon',
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.hairlineSoft,
              ),
            ),
            _MembershipRow(onTap: () => context.push('/membership/register')),
          ],
        ),
      ),
    );
  }
}

/// Satu angka ringkasan.
///
/// Nilainya sengaja "—". Tidak ada endpoint poin maupun kupon di backend, dan
/// saldo punya endpoint (`/wallet`) yang belum dipanggil aplikasi. Slotnya
/// disediakan supaya tinggal diisi begitu datanya benar-benar ada.
class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;

  const _SummaryStat({
    required this.icon,
    required this.tint,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppleRadii.control),
            ),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(fontSize: 11.5),
                ),
                Text(
                  '—',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedSoft,
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

class _MembershipRow extends StatelessWidget {
  final VoidCallback onTap;

  const _MembershipRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: 'Lihat Keanggotaan',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Lihat Keanggotaan',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedSoft,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Aktivitas Saya
// ─────────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_Activity>[
      _Activity(
        'Pesanan',
        Icons.inventory_2_rounded,
        AppColors.primary,
        () => context.go('/cart'),
      ),
      _Activity(
        'Favorit',
        Icons.favorite_rounded,
        AppColors.primary,
        () => _soon(context, 'Produk favorit'),
      ),
      _Activity(
        'Ulasan',
        Icons.chat_bubble_rounded,
        AppColors.warning,
        () => _soon(context, 'Ulasan saya'),
      ),
      _Activity(
        'Riwayat',
        Icons.receipt_long_rounded,
        AppColors.success,
        () => context.push('/orders/history'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: 'Aktivitas Saya',
          actionLabel: 'Lihat Semua',
          onAction: () => context.go('/cart'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: _ActivityCard(item: items[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Activity {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const _Activity(this.label, this.icon, this.tint, this.onTap);
}

class _ActivityCard extends StatelessWidget {
  final _Activity item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      onTap: item.onTap,
      radius: AppleRadii.tile,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppleRadii.control),
            ),
            child: Icon(item.icon, size: 20, color: item.tint),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bagian bertingkat
// ─────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MenuSection(
      title: 'Akun & Belanja',
      rows: [
        _MenuRow(
          icon: Icons.person_rounded,
          tint: AppColors.primary,
          label: 'Data Pribadi',
          onTap: () => _soon(context, 'Data pribadi'),
        ),
        _MenuRow(
          icon: Icons.location_on_rounded,
          tint: AppColors.success,
          label: 'Alamat Pengiriman',
          onTap: () => _soon(context, 'Alamat pengiriman'),
        ),
        _MenuRow(
          icon: Icons.credit_card_rounded,
          tint: AppColors.primary,
          label: 'Metode Pembayaran',
          onTap: () => _soon(context, 'Metode pembayaran'),
        ),
        _MenuRow(
          icon: Icons.groups_rounded,
          tint: AppColors.warning,
          label: 'Keanggotaan Koperasi',
          onTap: () => context.push('/membership/register'),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MenuSection(
      title: 'Pengaturan',
      rows: [
        _MenuRow(
          icon: Icons.notifications_rounded,
          tint: AppColors.primary,
          label: 'Notifikasi',
          onTap: () => context.push('/notifications'),
        ),
        _MenuRow(
          icon: Icons.shield_rounded,
          tint: AppColors.success,
          label: 'Privasi & Keamanan',
          onTap: () => _soon(context, 'Privasi & keamanan'),
        ),
        _MenuRow(
          icon: Icons.language_rounded,
          tint: AppColors.warning,
          label: 'Bahasa',
          trailing: 'Indonesia',
          onTap: () => _soon(context, 'Pengaturan bahasa'),
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MenuSection(
      title: 'Bantuan',
      rows: [
        _MenuRow(
          icon: Icons.help_rounded,
          tint: AppColors.success,
          label: 'Pusat Bantuan',
          onTap: () => _soon(context, 'Pusat bantuan'),
        ),
        _MenuRow(
          icon: Icons.headset_mic_rounded,
          tint: AppColors.primary,
          label: 'Hubungi Kopdes',
          onTap: () => _soon(context, 'Hubungi Kopdes'),
        ),
        _MenuRow(
          icon: Icons.info_rounded,
          tint: AppColors.warning,
          label: 'Tentang KMP Mitra',
          trailing: ProfileScreen._version.replaceFirst('KMP Mitra ', ''),
          onTap: () => _soon(context, 'Tentang KMP Mitra'),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _MenuSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        AppleListGroup(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          indent: 68,
          children: rows,
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppleRadii.control - 2),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTypography.captionSmall.copyWith(fontSize: 13),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedSoft,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Keluar
// ─────────────────────────────────────────────────────────────

class _LogoutRow extends ConsumerWidget {
  const _LogoutRow();

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk lagi untuk melihat pesanan dan keranjangmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    // Keluar itu tidak bisa dibatalkan dari sisi pengguna — satu ketukan tidak
    // sengaja pada baris terakhir halaman tidak boleh langsung menghapus sesi.
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: ApplePressable(
        onTap: () => _confirm(context, ref),
        semanticLabel: 'Keluar dari Akun',
        borderRadius: BorderRadius.circular(AppleRadii.group),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppleRadii.group),
            border: Border.all(color: AppColors.primarySoft, width: 1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 19,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  'Keluar dari Akun',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _soon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature belum tersedia.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),
  );
}
