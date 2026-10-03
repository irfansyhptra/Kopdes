import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../data/chat_models.dart';
import 'providers/chat_providers.dart';

// Memulai (atau membuka kembali) percakapan dengan [userId] lalu masuk ke ruang chat.
// Dipakai lintas fitur (mis. Admin menghubungi mitra/pelanggan).
Future<void> openChatWith(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String title, {
  ChatChannel channel = ChatChannel.general,
}) async {
  if (userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengguna tidak valid untuk dihubungi'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  try {
    final conv = await ref
        .read(chatServiceProvider)
        .startConversation(userId, channel: channel);
    ref.invalidate(conversationsProvider);
    ref.invalidate(channelConversationsProvider);
    if (context.mounted) {
      context.push(
        channel.detailPath(conv.id),
        extra: ChatDetailArguments(title: title, channel: channel),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
