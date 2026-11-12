enum ChatRole { system, user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;

  ChatMessage copyWith({String? content}) =>
      ChatMessage(role: role, content: content ?? this.content);
}
