import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/repositories/ai_settings_repository.dart';

class SecureAiSettingsRepository implements AiSettingsRepository {
  SecureAiSettingsRepository([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'ai_api_key';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readApiKey() => _storage.read(key: _keyName);

  @override
  Future<void> saveApiKey(String key) =>
      _storage.write(key: _keyName, value: key.trim());

  @override
  Future<void> clearApiKey() => _storage.delete(key: _keyName);
}
