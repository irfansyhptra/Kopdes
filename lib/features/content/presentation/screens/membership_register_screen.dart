import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../koperasi/presentation/providers/koperasi_provider.dart';
import '../../domain/content_page.dart';

/// Tujuan tombol "Daftar Sekarang".
///
/// Alur pendaftaran anggota **belum dibangun** — pemilihan Kopdes, verifikasi
/// identitas, jenis simpanan, dan persetujuan ketentuan semuanya menyentuh
/// keuangan anggota dan hanya boleh dibuat setelah ketentuan resmi koperasi
/// tersedia.
///
/// Layar ini mengatakan hal itu apa adanya dan mengarahkan pengguna ke
/// pengurus Kopdes. Membuat formulir yang seolah-olah berfungsi, atau
/// menampilkan langkah-langkah yang tidak mengirim apa pun, akan lebih buruk
/// daripada mengaku belum siap.
class MembershipRegisterScreen extends ConsumerWidget {
  const MembershipRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kontak diambil dari data Kopdes, bukan ditulis tetap di sini.
    final koperasi = ref.watch(koperasiListProvider);
    final phone = koperasi.valueOrNull?.items.firstOrNull?.phone;
    final name = koperasi.valueOrNull?.items.firstOrNull?.name;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(title: const Text('Pendaftaran Anggota')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.card),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pendaftaran online belum dibuka',
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pendaftaran anggota koperasi menyangkut simpanan dan hak '
                  'kepemilikan, sehingga hanya dapat dilakukan setelah Anda '
                  'menerima penjelasan resmi dan menyetujui ketentuan yang '
                  'berlaku di koperasi ini.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Untuk saat ini, silakan hubungi pengurus '
                  '${name ?? 'Kopdes'} secara langsung.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (phone != null && phone.isNotEmpty)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text('Hubungi $phone'),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push('/info/${ContentSlugs.manfaatAnggota}'),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Baca Ketentuan Keanggotaan'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Aplikasi ini tidak menerima setoran simpanan dalam bentuk apa pun '
            'dan tidak menjanjikan imbal hasil. Ketentuan yang mengikat adalah '
            'Anggaran Dasar dan Anggaran Rumah Tangga koperasi.',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
