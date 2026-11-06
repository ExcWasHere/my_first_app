abstract class UsageQuotaRepository {
  int get dailyLimit;
  Future<int> remaining();
  Future<bool> tryConsume();
}
