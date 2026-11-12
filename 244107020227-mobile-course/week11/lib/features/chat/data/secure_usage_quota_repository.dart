import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/repositories/usage_quota_repository.dart';
import 'ai_config.dart';

class SecureUsageQuotaRepository implements UsageQuotaRepository {
  SecureUsageQuotaRepository({
    FlutterSecureStorage? storage,
    DateTime Function()? now,
    this.dailyLimit = AiConfig.dailyLimit,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _now = now ?? DateTime.now;

  @override
  final int dailyLimit;

  static const _dateKey = 'ai_quota_date';
  static const _countKey = 'ai_quota_count';

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  String _today() {
    final d = _now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<int> _used() async {
    if (await _storage.read(key: _dateKey) != _today()) return 0;
    return int.tryParse(await _storage.read(key: _countKey) ?? '') ?? 0;
  }

  @override
  Future<int> remaining() async {
    final left = dailyLimit - await _used();
    return left < 0 ? 0 : left;
  }

  @override
  Future<bool> tryConsume() async {
    final used = await _used();
    if (used >= dailyLimit) return false;
    await _storage.write(key: _dateKey, value: _today());
    await _storage.write(key: _countKey, value: '${used + 1}');
    return true;
  }
}
