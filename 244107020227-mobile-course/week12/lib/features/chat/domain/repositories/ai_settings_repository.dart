abstract class AiSettingsRepository {
  Future<String?> readApiKey();
  Future<void> saveApiKey(String key);
  Future<void> clearApiKey();
}
