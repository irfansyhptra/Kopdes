import 'package:dio/dio.dart';
import 'chat_models.dart';

// Klien HTTP fitur chat. Envelope backend: { success, data }.
class ChatService {
  final Dio dio;
  ChatService({required this.dio});

  Future<List<Conversation>> getConversations({ChatChannel? channel}) async {
    final res = await dio.get(
      '/chat/conversations',
      queryParameters: channel == null || channel == ChatChannel.general
          ? null
          : {'channel': channel.apiValue},
    );
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  Future<Conversation> startConversation(
    String recipientId, {
    ChatChannel channel = ChatChannel.general,
  }) async {
    final res = await dio.post(
      '/chat/conversations',
      data: {
        'recipientId': recipientId,
        if (channel != ChatChannel.general) 'channel': channel.apiValue,
      },
    );
    return Conversation.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<Conversation> startProductSellerConversation(String productId) async {
    final res = await dio.post('/chat/conversations/product/$productId/seller');
    return Conversation.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<Conversation> startUmkmProductSellerConversation(
    String productId,
  ) async {
    final res = await dio.post(
      '/chat/conversations/umkm-product/$productId/seller',
    );
    return Conversation.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<Conversation> startOrderConversation(
    String orderId, {
    required ChatChannel channel,
  }) async {
    assert(channel != ChatChannel.general);
    final target = channel == ChatChannel.delivery ? 'courier' : 'customer';
    final res = await dio.post('/chat/conversations/order/$orderId/$target');
    return Conversation.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final res = await dio.get('/chat/conversations/$conversationId/messages');
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    final res = await dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return ChatMessage.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> markRead(String conversationId) async {
    await dio.patch('/chat/conversations/$conversationId/read');
  }
}
