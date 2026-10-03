import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/chat_launcher.dart';

/// Kapsul "Chat Toko".
///
/// Tidak digambar sama sekali tanpa [ownerUserId]: tombol yang selalu menjawab
/// "pengguna tidak valid" lebih buruk daripada tombol yang tidak ada. Koperasi
/// tanpa pengurus dan mitra tanpa pemilik memang belum bisa dihubungi.
class StoreChatButton extends ConsumerWidget {
  final String? ownerUserId;

  /// Nama toko — dipakai sebagai judul ruang percakapan, supaya pembeli tahu
  /// sedang bicara dengan siapa.
  final String storeName;

  const StoreChatButton({
    super.key,
    required this.ownerUserId,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ownerUserId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();

    return ApplePressable(
      onTap: () => openChatWith(
        context,
        ref,
        id,
        storeName,
        // Kanal marketplace: percakapan jual-beli terpisah dari kanal umum
        // supaya pesan tentang pesanan tidak tercampur dengan urusan lain.
        channel: ChatChannel.marketplace,
      ),
      semanticLabel: 'Chat $storeName',
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppElevation.subtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Chat Toko',
              style: AppTypography.buttonSm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
