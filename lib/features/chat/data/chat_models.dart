// Model chat ringan (tanpa Freezed).

enum ChatChannel {
  marketplace('MARKETPLACE', 'seller'),
  delivery('DELIVERY', 'courier'),
  general('GENERAL', 'detail');

  final String apiValue;
  final String pathSegment;

  const ChatChannel(this.apiValue, this.pathSegment);

  factory ChatChannel.fromApi(Object? value) {
    return ChatChannel.values.firstWhere(
      (channel) => channel.apiValue == value,
      orElse: () => ChatChannel.general,
    );
  }

  String detailPath(String conversationId) =>
      '/chat/$pathSegment/$conversationId';
}

class ChatDetailArguments {
  final String title;
  final ChatChannel channel;

  const ChatDetailArguments({required this.title, required this.channel});
}

class ChatUser {
  final String id;
  final String name;
  final String role;
  ChatUser({required this.id, required this.name, required this.role});

  factory ChatUser.fromJson(Map<String, dynamic> j) => ChatUser(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '-',
    role: j['role'] as String? ?? '',
  );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool read;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    senderId: j['senderId'] as String? ?? '',
    content: j['content'] as String? ?? '',
    createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
    read: j['readAt'] != null,
  );
}

class Conversation {
  final String id;
  final ChatUser otherUser;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final ChatChannel channel;

  Conversation({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.channel = ChatChannel.general,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final last = j['lastMessage'] as Map<String, dynamic>?;
    return Conversation(
      id: j['id'] as String,
      otherUser: ChatUser.fromJson(
        j['otherUser'] as Map<String, dynamic>? ?? {},
      ),
      lastMessage: last?['content'] as String?,
      lastMessageAt:
          DateTime.tryParse('${j['lastMessageAt']}') ?? DateTime.now(),
      unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      channel: ChatChannel.fromApi(j['channel']),
    );
  }
}
