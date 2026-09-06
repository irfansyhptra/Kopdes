import 'package:dio/dio.dart';
import 'chat_models.dart';

// Klien HTTP fitur chat. Envelope backend: { success, data }.
class ChatService {
  final Dio dio;
  ChatService({required this.dio});

  Future<List<Conversation>> getConversations() async {
    final res = await dio.get('/chat/conversations');
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .cast<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  Future<Conversation> startConversation(String recipientId) async {
    final res = await dio.post(
      '/chat/conversations',
      data: {'recipientId': recipientId},
    );
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
