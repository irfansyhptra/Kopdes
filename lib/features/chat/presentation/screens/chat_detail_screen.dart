import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_models.dart';
import '../../domain/chat_channel_logic.dart';
import '../providers/chat_providers.dart';

/// Ruang chat bersama untuk transaksi dan pengantaran. Polling hanya aktif
/// saat aplikasi berada di foreground agar tidak membuat permintaan sia-sia.
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  final ChatChannel channel;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.channel = ChatChannel.general,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _poll;
  bool _sending = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markRead();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(messagesProvider(widget.conversationId));
      _markRead();
      _startPolling();
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.invalidate(messagesProvider(widget.conversationId));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(chatServiceProvider).markRead(widget.conversationId);
      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
    } catch (_) {
      // Membaca pesan tetap boleh dilanjutkan ketika status read gagal disimpan.
    }
  }

  void _useQuickReply(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _canSend = true);
    _focusNode.requestFocus();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _canSend = false;
    });
    _controller.clear();

    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(widget.conversationId, text);
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
    } catch (error) {
      if (mounted) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
        setState(() => _canSend = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan belum terkirim. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final user = ref.watch(authProvider).user;
    final meId = user?.id;
    final role = user?.role;
    final quickReplies = ChatChannelLogic.quickReplies(widget.channel, role);

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
              : context.go('/chat/${widget.channel.pathSegment}'),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.channel == ChatChannel.delivery
                  ? const Color(0xFFFFE8C2)
                  : AppColors.primarySoft,
              child: Text(
                widget.title.trim().isEmpty
                    ? '?'
                    : widget.title.trim()[0].toUpperCase(),
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.channel == ChatChannel.delivery
                      ? const Color(0xFF9A5B00)
                      : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.channel == ChatChannel.delivery
                        ? 'Koordinasi pengantaran'
                        : widget.channel == ChatChannel.marketplace
                        ? 'Percakapan pesanan'
                        : 'Percakapan',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => _MessageState(
                title: 'Percakapan belum dapat dimuat',
                actionLabel: 'Coba Lagi',
                onAction: () =>
                    ref.invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _MessageState(
                    title: 'Belum ada pesan',
                    message: 'Mulai percakapan dengan pesan yang jelas.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final message = items[items.length - 1 - index];
                    return _Bubble(
                      message: message,
                      mine: message.senderId == meId,
                    );
                  },
                );
              },
            ),
          ),
          if (quickReplies.isNotEmpty)
            Container(
              color: AppColors.canvas,
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  itemCount: quickReplies.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(quickReplies[index]),
                    onPressed: () => _useQuickReply(quickReplies[index]),
                    backgroundColor: AppColors.canvas,
                    side: const BorderSide(color: AppColors.hairline),
                    labelStyle: AppTypography.captionSmall.copyWith(
                      color: AppColors.body,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(4000)],
                onChanged: (value) {
                  final canSend = value.trim().isNotEmpty;
                  if (canSend != _canSend) {
                    setState(() => _canSend = canSend);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tulis pesan…',
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Kirim pesan',
                onPressed: _canSend && !_sending ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.hairline,
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: mine ? 'Pesan Anda' : 'Pesan masuk',
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.canvas,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.card),
              topRight: const Radius.circular(AppRadius.card),
              bottomLeft: Radius.circular(mine ? AppRadius.card : AppRadius.xs),
              bottomRight: Radius.circular(
                mine ? AppRadius.xs : AppRadius.card,
              ),
            ),
            border: mine ? null : Border.all(color: AppColors.hairlineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('HH:mm').format(message.createdAt.toLocal()),
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 9,
                  color: mine
                      ? AppColors.onPrimary.withValues(alpha: 0.72)
                      : AppColors.mutedSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 46,
              color: AppColors.mutedSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
