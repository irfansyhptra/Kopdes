import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_models.dart';
import '../../domain/chat_channel_logic.dart';
import '../providers/chat_providers.dart';

class ChatHubScreen extends ConsumerWidget {
  const ChatHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role;
    final channels = ChatChannelLogic.channelsForRole(role);
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(ChatChannelLogic.landingPath(role)),
        ),
        title: Text(
          'Pesan',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(conversationsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB00020), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Percakapan lebih terarah',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pesan transaksi dan koordinasi pengantaran dipisahkan agar informasi penting mudah ditemukan.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.86),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pilih jenis percakapan',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final channel in channels) ...[
              _ChannelCard(
                channel: channel,
                role: role,
                unreadCount: conversations.maybeWhen(
                  data: (items) => items
                      .where((item) => item.channel == channel)
                      .fold(0, (sum, item) => sum + item.unreadCount),
                  orElse: () => 0,
                ),
                loading: conversations.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ChatChannel channel;
  final String? role;
  final int unreadCount;
  final bool loading;

  const _ChannelCard({
    required this.channel,
    required this.role,
    required this.unreadCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final delivery = channel == ChatChannel.delivery;
    return Semantics(
      button: true,
      label: ChatChannelLogic.title(channel, role),
      child: Material(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push('/chat/${channel.pathSegment}'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.hairlineSoft),
              boxShadow: AppElevation.hairline,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: delivery
                        ? const Color(0xFFFFF2DC)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Icon(
                    delivery
                        ? Icons.local_shipping_rounded
                        : Icons.storefront_rounded,
                    color: delivery
                        ? const Color(0xFFB66A00)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ChatChannelLogic.title(channel, role),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ChatChannelLogic.description(channel, role),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: AppTypography.badge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
