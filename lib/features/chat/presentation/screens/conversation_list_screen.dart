import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../data/chat_models.dart';
import '../providers/chat_providers.dart';

// Daftar percakapan pengguna (dipakai Admin Kopdes maupun peran lain).
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convs = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Text(
          'Pesan',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: convs.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 44,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gagal memuat pesan:\n$e',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(conversationsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    size: 56,
                    color: AppColors.mutedSoft,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada percakapan.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppColors.hairlineSoft, height: 1, indent: 72),
              itemBuilder: (context, i) => _ConversationTile(conv: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unreadCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 4,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primarySoft,
        child: Text(
          conv.otherUser.name.isNotEmpty
              ? conv.otherUser.name[0].toUpperCase()
              : '?',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(
        conv.otherUser.name,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conv.lastMessage ?? 'Mulai percakapan…',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.captionSmall.copyWith(
          color: hasUnread ? AppColors.ink : AppColors.muted,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(conv.lastMessageAt.toLocal()),
            style: AppTypography.captionSmall.copyWith(
              fontSize: 10,
              color: AppColors.mutedSoft,
            ),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conv.unreadCount}',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${conv.id}', extra: conv.otherUser.name),
    );
  }
}
