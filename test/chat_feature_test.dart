import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/chat/data/chat_models.dart';
import 'package:kopdes/features/chat/data/chat_service.dart';
import 'package:kopdes/features/chat/domain/chat_channel_logic.dart';
import 'package:kopdes/features/chat/presentation/providers/chat_providers.dart';
import 'package:kopdes/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:kopdes/features/chat/presentation/screens/conversation_list_screen.dart';

class _FakeChatService extends ChatService {
  _FakeChatService() : super(dio: Dio());

  final conversations = <Conversation>[
    Conversation(
      id: 'conversation-1',
      otherUser: ChatUser(id: 'seller-1', name: 'Toko Lamteh', role: 'UMKM'),
      lastMessage: 'Pesanan sedang disiapkan.',
      lastMessageAt: DateTime(2026, 9, 29, 10),
      unreadCount: 2,
      channel: ChatChannel.marketplace,
    ),
  ];

  @override
  Future<List<Conversation>> getConversations({ChatChannel? channel}) async {
    if (channel == null || channel == ChatChannel.general) return conversations;
    return conversations.where((item) => item.channel == channel).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async => [];

  @override
  Future<void> markRead(String conversationId) async {}
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(320, 568),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [chatServiceProvider.overrideWithValue(_FakeChatService())],
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Logika kanal chat', () {
    test('penjual mendapat kanal pembeli dan kanal kurir', () {
      expect(ChatChannelLogic.channelsForRole('UMKM'), [
        ChatChannel.marketplace,
        ChatChannel.delivery,
      ]);
      expect(
        ChatChannelLogic.title(ChatChannel.marketplace, 'UMKM'),
        'Chat Pembeli',
      );
      expect(
        ChatChannelLogic.title(ChatChannel.delivery, 'UMKM'),
        'Chat Kurir',
      );
    });

    test('pembeli dan kurir hanya melihat kanal yang relevan', () {
      expect(ChatChannelLogic.channelsForRole('CUSTOMER'), [
        ChatChannel.marketplace,
      ]);
      expect(ChatChannelLogic.channelsForRole('COURIER'), [
        ChatChannel.delivery,
      ]);
    });

    test('response API membaca tipe kanal', () {
      final conversation = Conversation.fromJson({
        'id': 'c1',
        'otherUser': {'id': 'u2', 'name': 'Kurir Desa', 'role': 'COURIER'},
        'lastMessageAt': '2026-09-29T10:00:00Z',
        'unreadCount': 1,
        'channel': 'DELIVERY',
      });
      expect(conversation.channel, ChatChannel.delivery);
      expect(conversation.unreadCount, 1);
    });
  });

  group('Halaman chat', () {
    testWidgets('daftar chat penjual aman pada layar 320dp', (tester) async {
      await _pump(
        tester,
        const ConversationListScreen(channel: ChatChannel.marketplace),
      );

      expect(find.text('Chat Penjual'), findsOneWidget);
      expect(find.text('Toko Lamteh'), findsOneWidget);
      expect(find.text('Pesanan sedang disiapkan.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail pengantaran menampilkan balasan cepat', (tester) async {
      await _pump(
        tester,
        const ChatDetailScreen(
          conversationId: 'conversation-1',
          title: 'Kurir Desa',
          channel: ChatChannel.delivery,
        ),
      );

      expect(find.text('Koordinasi pengantaran'), findsOneWidget);
      expect(find.text('Paket siap diambil.'), findsOneWidget);
      expect(find.text('Belum ada pesan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
