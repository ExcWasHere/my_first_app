import '../../../../core/failures.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../entities/chat_message.dart';
import '../repositories/ai_settings_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/usage_quota_repository.dart';
import 'build_chat_prompt.dart';

class SendChatMessage {
  const SendChatMessage({
    required this.chat,
    required this.settings,
    required this.quota,
    this.buildPrompt = const BuildChatPrompt(),
    this.maxQuestionChars = 500,
  });

  final ChatRepository chat;
  final AiSettingsRepository settings;
  final UsageQuotaRepository quota;
  final BuildChatPrompt buildPrompt;
  final int maxQuestionChars;

  Stream<String> call({
    required List<Announcement> announcements,
    required List<ChatMessage> history,
    required String question,
  }) async* {
    final text = question.trim();
    if (text.isEmpty) {
      throw const ValidationFailure('Pertanyaan tidak boleh kosong.');
    }
    if (text.length > maxQuestionChars) {
      throw ValidationFailure('Pertanyaan maksimal $maxQuestionChars karakter.');
    }
    final key = await settings.readApiKey();
    if (key == null || key.isEmpty) {
      throw const ValidationFailure('API key belum diatur.');
    }
    if (!await quota.tryConsume()) {
      throw const LocalFailure(
        'Batas penggunaan AI hari ini sudah habis. Coba lagi besok.',
      );
    }
    yield* chat.streamCompletion(
      buildPrompt(
        announcements: announcements,
        history: history,
        question: text,
      ),
    );
  }
}
