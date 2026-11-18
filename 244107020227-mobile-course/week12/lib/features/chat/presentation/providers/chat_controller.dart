import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/failures.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../../../announcements/presentation/providers/announcements_providers.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_providers.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? error;
}

class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _sub;

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ChatState();
  }

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.isStreaming) return;
    final history = state.messages;
    state = ChatState(
      messages: [
        ...history,
        ChatMessage(role: ChatRole.user, content: text),
        const ChatMessage(role: ChatRole.assistant, content: ''),
      ],
      isStreaming: true,
    );
    final announcements = await _loadAnnouncements();
    if (!state.isStreaming) return;
    final stream = ref.read(sendChatMessageProvider).call(
          announcements: announcements,
          history: history,
          question: text,
        );
    _sub = stream.listen(
      _onChunk,
      onError: (Object e) => _onError(e, announcements),
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  void retry() {
    if (state.isStreaming) return;
    final i = state.messages.lastIndexWhere((m) => m.role == ChatRole.user);
    if (i < 0) return;
    final text = state.messages[i].content;
    state = ChatState(messages: state.messages.sublist(0, i));
    send(text);
  }

  void clear() {
    _sub?.cancel();
    state = const ChatState();
  }

  Future<List<Announcement>> _loadAnnouncements() async {
    try {
      return await ref.read(announcementsProvider.future);
    } catch (_) {
      return const <Announcement>[];
    }
  }

  void _onChunk(String chunk) {
    final msgs = [...state.messages];
    final last = msgs.removeLast();
    msgs.add(last.copyWith(content: last.content + chunk));
    state = ChatState(messages: msgs, isStreaming: true);
  }

  void _onError(Object error, List<Announcement> announcements) {
    final msgs = [...state.messages];
    final noReply = msgs.isNotEmpty && msgs.last.content.isEmpty;
    if (noReply) msgs.removeLast();
    if (noReply && error is NetworkFailure) {
      final offline = ref.read(buildOfflineAnswerProvider).call(announcements);
      msgs.add(ChatMessage(role: ChatRole.assistant, content: offline));
    }
    state = ChatState(messages: msgs, error: messageOf(error));
    ref.invalidate(remainingQuotaProvider);
  }

  void _onDone() {
    state = ChatState(messages: state.messages);
    ref.invalidate(remainingQuotaProvider);
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
