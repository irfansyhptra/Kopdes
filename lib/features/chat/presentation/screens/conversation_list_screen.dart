import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_models.dart';
import '../../domain/chat_channel_logic.dart';
import '../providers/chat_providers.dart';

/// Daftar percakapan untuk satu kanal. Marketplace dan pengantaran memakai
/// instance berbeda sehingga pesan pembeli tidak bercampur dengan kurir.
class ConversationListScreen extends ConsumerStatefulWidget {
  final ChatChannel channel;

  const ConversationListScreen({super.key, this.channel = ChatChannel.general});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).user?.role;
    final conversations = widget.channel == ChatChannel.general
        ? ref.watch(conversationsProvider)
        : ref.watch(channelConversationsProvider(widget.channel));
    final title = ChatChannelLogic.title(widget.channel, role);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(
                  widget.channel == ChatChannel.general
                      ? ChatChannelLogic.landingPath(role)
                      : '/chat',
                ),
        ),
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              0,
              AppSpacing.base,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama atau pesan',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          Expanded(
            child: conversations.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => _ChatListState(
                icon: Icons.cloud_off_rounded,
                title: 'Pesan belum dapat dimuat',
                message: 'Periksa koneksi lalu coba lagi.',
                actionLabel: 'Coba Lagi',
                onAction: () => _refresh(ref),
              ),
              data: (items) {
                final filtered = items.where((conversation) {
                  if (_query.isEmpty) return true;
                  return conversation.otherUser.name.toLowerCase().contains(
                        _query,
                      ) ||
                      (conversation.lastMessage ?? '').toLowerCase().contains(
                        _query,
                      );
                }).toList();

                if (filtered.isEmpty) {
                  return _ChatListState(
                    icon: _query.isEmpty
                        ? Icons.forum_outlined
                        : Icons.search_off_rounded,
                    title: _query.isEmpty
                        ? 'Belum ada percakapan'
                        : 'Percakapan tidak ditemukan',
                    message: _query.isEmpty
                        ? ChatChannelLogic.emptyMessage(widget.channel, role)
                        : 'Coba gunakan nama atau kata kunci lain.',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _refresh(ref),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.hairlineSoft,
                      height: 1,
                      indent: 84,
                    ),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: filtered[index],
                      channel: widget.channel,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    if (widget.channel == ChatChannel.general) {
      ref.invalidate(conversationsProvider);
    } else {
      ref.invalidate(channelConversationsProvider(widget.channel));
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final ChatChannel channel;

  const _ConversationTile({required this.conversation, required this.channel});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    final initial = conversation.otherUser.name.trim().isEmpty
        ? '?'
        : conversation.otherUser.name.trim()[0].toUpperCase();

    return Material(
      color: AppColors.canvas,
      child: InkWell(
        onTap: () => context.push(
          channel.detailPath(conversation.id),
          extra: ChatDetailArguments(
            title: conversation.otherUser.name,
            channel: channel,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: channel == ChatChannel.delivery
                    ? const Color(0xFFFFE8C2)
                    : AppColors.primarySoft,
                child: Text(
                  initial,
                  style: AppTypography.titleMedium.copyWith(
                    color: channel == ChatChannel.delivery
                        ? const Color(0xFF9A5B00)
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _timeLabel(conversation.lastMessageAt),
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 10,
                            color: unread
                                ? AppColors.primary
                                : AppColors.mutedSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ChatChannelLogic.roleLabel(conversation.otherUser.role),
                      style: AppTypography.badge.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'Mulai percakapan…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSmall.copyWith(
                              color: unread ? AppColors.ink : AppColors.muted,
                              fontWeight: unread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: AppTypography.badge.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(local)
        : DateFormat('dd/MM').format(local);
  }
}

class _ChatListState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ChatListState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.mutedSoft),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
