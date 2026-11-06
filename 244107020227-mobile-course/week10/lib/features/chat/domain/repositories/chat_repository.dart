import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<String> streamCompletion(List<ChatMessage> messages);
}
