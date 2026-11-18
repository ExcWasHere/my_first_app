import 'package:week10/features/chat/domain/entities/chat_message.dart';
import 'package:week10/features/chat/domain/repositories/ai_settings_repository.dart';
import 'package:week10/features/chat/domain/repositories/chat_repository.dart';
import 'package:week10/features/chat/domain/repositories/usage_quota_repository.dart';

/// Fake chat: mengalirkan [chunks], lalu melempar [error] bila diisi.
class FakeChat implements ChatRepository {
  FakeChat(this.chunks, {this.error});

  final List<String> chunks;
  final Object? error;
  int calls = 0;
  List<ChatMessage>? lastMessages;

  @override
  Stream<String> streamCompletion(List<ChatMessage> messages) async* {
    calls++;
    lastMessages = messages;
    for (final c in chunks) {
      yield c;
    }
    if (error != null) throw error!;
  }
}

class FakeSettings implements AiSettingsRepository {
  FakeSettings(this.key);

  String? key;

  @override
  Future<String?> readApiKey() async => key;

  @override
  Future<void> saveApiKey(String value) async => key = value;

  @override
  Future<void> clearApiKey() async => key = null;
}

class FakeQuota implements UsageQuotaRepository {
  FakeQuota(this.left);

  int left;

  @override
  int get dailyLimit => 30;

  @override
  Future<int> remaining() async => left;

  @override
  Future<bool> tryConsume() async {
    if (left <= 0) return false;
    left--;
    return true;
  }
}
