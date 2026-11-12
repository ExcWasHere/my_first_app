import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/groq_chat_repository.dart';
import '../../data/secure_ai_settings_repository.dart';
import '../../data/secure_usage_quota_repository.dart';
import '../../domain/repositories/ai_settings_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/usage_quota_repository.dart';
import '../../domain/usecases/build_offline_answer.dart';
import '../../domain/usecases/send_chat_message.dart';

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>(
  (ref) => SecureAiSettingsRepository(),
);

final usageQuotaRepositoryProvider = Provider<UsageQuotaRepository>(
  (ref) => SecureUsageQuotaRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => GroqChatRepository(
    settings: ref.watch(aiSettingsRepositoryProvider),
  ),
);

final sendChatMessageProvider = Provider<SendChatMessage>(
  (ref) => SendChatMessage(
    chat: ref.watch(chatRepositoryProvider),
    settings: ref.watch(aiSettingsRepositoryProvider),
    quota: ref.watch(usageQuotaRepositoryProvider),
  ),
);

final buildOfflineAnswerProvider = Provider<BuildOfflineAnswer>(
  (ref) => const BuildOfflineAnswer(),
);

final apiKeyPresentProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(aiSettingsRepositoryProvider).readApiKey();
  return key != null && key.isNotEmpty;
});

final remainingQuotaProvider = FutureProvider<int>(
  (ref) => ref.watch(usageQuotaRepositoryProvider).remaining(),
);
