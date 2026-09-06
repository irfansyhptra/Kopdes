import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_service.dart';
import '../../data/chat_models.dart';

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(dio: ref.watch(dioProvider)),
);

// ID pengguna saat ini (untuk menentukan sisi bubble chat).
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).user?.id,
);

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  return ref.watch(chatServiceProvider).getConversations();
});

final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) async {
  return ref.watch(chatServiceProvider).getMessages(conversationId);
});
