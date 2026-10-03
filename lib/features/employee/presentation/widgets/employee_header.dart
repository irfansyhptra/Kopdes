import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../domain/employee_dashboard.dart';
import '../employee_theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../providers/employee_providers.dart';

/// Header compact dashboard pegawai.
///
/// Tingginya ditahan di kisaran 155–185 dp: bagian ini identitas, bukan
/// isi — setiap dp tambahan diambil dari KPI yang justru dibaca tiap pagi.
class KopdesEmployeeHeader extends ConsumerWidget {
  const KopdesEmployeeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentStaffProvider);
    final store = ref.watch(storeStatusProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    // Bentuk kepalanya — gradien, radius, jarak aman, dan tombol kacanya —
    // datang dari `GlassPageHeader`, sama dengan kepala peran lain. Yang
    // tinggal di sini hanya isi khusus pegawai: sapaan dan status toko.
    return GlassPageHeader(
      title: 'KMP Mitra',
      subtitle: _todayLabel(DateTime.now()),
      actions: [
        GlassIconButton(
          icon: Icons.notifications_none_rounded,
          label: 'Notifikasi',
          badge: unread,
          onDark: true,
          onTap: () => context.push('/notifications'),
        ),
        _Avatar(name: user?.name ?? ''),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Greeting(user: user),
          const SizedBox(height: KopdesSpacing.md),
          _StatusRow(store: store),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return GestureDetector(
      onTap: () => context.push('/pegawai/profil'),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Selamat Bekerja,',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 13,
          ),
        ),
        Text(
          user?.name ?? 'Pegawai',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.store});

  final AsyncValue<StoreStatus?> store;

  @override
  Widget build(BuildContext context) {
    // Wrap, bukan Row: pada 320 dp dengan skala teks 2.0x tiga lencana ini
    // tidak muat sebaris, dan memaksanya sebaris akan memotong tulisannya.
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(currentStaffProvider);
        final kopdesName =
            store.valueOrNull?.name ?? user?.kopdesName ?? 'Kopdes Merah Putih';

        return Wrap(
          spacing: KopdesSpacing.sm,
          runSpacing: KopdesSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Badge(
              label: user?.roleLabel ?? 'Pegawai Kopdes',
              background: Colors.white,
              foreground: KopdesEmployeeColors.darkRed,
            ),
            _Badge(
              label: kopdesName,
              background: Colors.white.withValues(alpha: 0.18),
              foreground: Colors.white,
              icon: Icons.storefront_rounded,
            ),
            store.when(
              // Status toko datang dari jadwal operasional, jadi selama belum
              // terbaca lebih baik diam daripada menebak "Tutup".
              loading: () => const _Badge(
                label: 'Memuat status…',
                background: Color(0x33FFFFFF),
                foreground: Colors.white,
              ),
              error: (_, _) => const _Badge(
                label: 'Status toko tidak tersedia',
                background: Color(0x33FFFFFF),
                foreground: Colors.white,
              ),
              data: (status) => _Badge(
                label: status?.label ?? 'Jadwal belum diatur',
                background: Colors.white.withValues(alpha: 0.18),
                foreground: Colors.white,
                icon: switch (status?.isOpen) {
                  true => Icons.check_circle_rounded,
                  false => Icons.do_not_disturb_on_rounded,
                  null => Icons.schedule_rounded,
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KopdesRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _todayLabel(DateTime now) {
  final day = _days[(now.weekday - 1) % 7];
  return '$day, ${now.day} ${_months[now.month - 1]} ${now.year}';
}
