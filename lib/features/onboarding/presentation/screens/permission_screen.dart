import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Layar tindak lanjut saat ada izin yang tidak diberikan.
///
/// Tidak pernah tampil lebih dulu. Dialog sistem diminta langsung begitu
/// beranda terbuka (`HomeScreen._askPermissions`); yang mengizinkan semuanya
/// tidak pernah melihat layar ini sama sekali. Ia baru didorong ketika ada
/// yang ditolak — dan pada saat itulah menjelaskan alasannya baru ada
/// gunanya, karena orangnya sudah tahu apa yang sedang ditanyakan.
///
/// Tetap bukan gerbang: tombol "Lanjutkan" selalu aktif dan menolak tidak
/// menghentikan siapa pun. Izin yang ditolak permanen hanya bisa dipulihkan
/// lewat Pengaturan perangkat, jadi kartunya menawarkan jalan ke sana alih-alih
/// memanggil dialog yang tidak akan pernah muncul lagi.
///
/// Tiap kartu menyebut apa yang bisa dilakukan aplikasi dengan izin tersebut,
/// dan apa yang tetap berjalan tanpanya — supaya menolak terasa sebagai
/// pilihan, bukan kehilangan yang tidak jelas besarnya.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final Map<Permission, PermissionStatus> _status = {};
  Permission? _asking;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Membaca keadaan sekarang tanpa memunculkan dialog apa pun.
  Future<void> _refresh() async {
    for (final item in _items) {
      final status = await item.permission.status;
      if (!mounted) return;
      setState(() => _status[item.permission] = status);
    }
  }

  Future<void> _request(_PermissionItem item) async {
    setState(() => _asking = item.permission);
    final status = await item.permission.request();
    if (!mounted) return;
    setState(() {
      _status[item.permission] = status;
      _asking = null;
    });

    // Ditolak permanen berarti dialog sistem tidak akan muncul lagi; satu-
    // satunya jalan tersisa adalah Pengaturan perangkat.
    if (status.isPermanentlyDenied && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text('Izin ${item.title} dimatikan'),
          content: const Text(
            'Android tidak akan menanyakannya lagi dari dalam aplikasi. '
            'Izinnya bisa dinyalakan lewat Pengaturan perangkat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      if (open == true) await openAppSettings();
    }
  }

  /// Penandanya sudah dipasang di beranda sebelum layar ini didorong, jadi di
  /// sini cukup menutup.
  void _continue() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.lg,
                  AppSpacing.base,
                  AppSpacing.base,
                ),
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(AppleRadii.tile),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Ada izin yang belum aktif',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Aplikasi tetap bisa dipakai tanpanya — hanya bagian yang '
                    'bersangkutan yang mati. Nyalakan yang kamu perlukan saja.',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final item in _items) ...[
                    _PermissionCard(
                      item: item,
                      status: _status[item.permission],
                      busy: _asking == item.permission,
                      onRequest: () => _request(item),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: ApplePressable(
                onTap: _continue,
                semanticLabel: 'Lanjutkan',
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: AppElevation.accent,
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: AppTypography.buttonSm.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
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

// ─────────────────────────────────────────────────────────────
// Daftar izin
// ─────────────────────────────────────────────────────────────

class _PermissionItem {
  final Permission permission;
  final IconData icon;
  final Color tint;
  final String title;

  /// Apa yang bisa dilakukan aplikasi dengan izin ini.
  final String purpose;

  /// Apa yang tetap berjalan tanpanya — supaya menolak terasa sebagai pilihan,
  /// bukan sebagai kehilangan yang tidak jelas besarnya.
  final String withoutIt;

  const _PermissionItem({
    required this.permission,
    required this.icon,
    required this.tint,
    required this.title,
    required this.purpose,
    required this.withoutIt,
  });
}

const List<_PermissionItem> _items = [
  _PermissionItem(
    permission: Permission.notification,
    icon: Icons.notifications_rounded,
    tint: AppColors.primary,
    title: 'Notifikasi',
    purpose:
        'Mengabari status pesanan, kurir yang berangkat, dan pesan dari Kopdes '
        'langsung ke perangkatmu.',
    withoutIt: 'Tanpa ini, kabar pesanan hanya terlihat saat aplikasi dibuka.',
  ),
  _PermissionItem(
    permission: Permission.locationWhenInUse,
    icon: Icons.location_on_rounded,
    tint: AppColors.success,
    title: 'Lokasi',
    purpose:
        'Menemukan Kopdes dan UMKM terdekat, dan melacak posisi kurir saat '
        'pesananmu diantar.',
    withoutIt: 'Tanpa ini, Kopdes ditampilkan tanpa urutan jarak.',
  ),
  _PermissionItem(
    permission: Permission.photos,
    icon: Icons.photo_library_rounded,
    tint: AppColors.warning,
    title: 'Galeri',
    purpose:
        'Memilih foto untuk profil, bukti penerimaan pesanan, dan foto produk '
        'bila kamu berjualan.',
    withoutIt: 'Tanpa ini, foto hanya bisa diambil langsung dari kamera.',
  ),
];

// ─────────────────────────────────────────────────────────────
// Kartu
// ─────────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final _PermissionItem item;
  final PermissionStatus? status;
  final bool busy;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.item,
    required this.status,
    required this.busy,
    required this.onRequest,
  });

  bool get _granted => status?.isGranted ?? false;
  bool get _blocked => status?.isPermanentlyDenied ?? false;

  String get _actionLabel {
    if (_granted) return 'Diizinkan';
    if (_blocked) return 'Buka Pengaturan';
    return 'Izinkan';
  }

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (_granted)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.purpose,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.withoutIt,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          if (!_granted) ...[
            const SizedBox(height: AppSpacing.base),
            ApplePressable(
              onTap: busy ? null : onRequest,
              semanticLabel: '$_actionLabel ${item.title}',
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.primarySoft, width: 1),
                ),
                child: Text(
                  _actionLabel,
                  style: AppTypography.buttonSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
