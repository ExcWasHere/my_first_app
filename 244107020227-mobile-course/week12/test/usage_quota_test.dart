import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/features/chat/data/secure_usage_quota_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime(2026, 11, 19, 8);
  SecureUsageQuotaRepository build() =>
      SecureUsageQuotaRepository(dailyLimit: 2, now: () => clock);

  setUp(() {
    clock = DateTime(2026, 11, 19, 8);
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('kuota awal penuh', () async {
    expect(await build().remaining(), 2);
  });

  test('setiap permintaan mengurangi kuota sampai habis', () async {
    final quota = build();
    expect(await quota.tryConsume(), isTrue);
    expect(await quota.tryConsume(), isTrue);
    expect(await quota.tryConsume(), isFalse);
    expect(await quota.remaining(), 0);
  });

  test('kuota direset pada hari berikutnya', () async {
    final quota = build();
    await quota.tryConsume();
    await quota.tryConsume();
    expect(await quota.remaining(), 0);

    clock = DateTime(2026, 11, 20, 0, 5);

    expect(await quota.remaining(), 2);
    expect(await quota.tryConsume(), isTrue);
  });

  test('hitungan tersimpan rusak dianggap nol, bukan error', () async {
    FlutterSecureStorage.setMockInitialValues({
      'ai_quota_date': '2026-11-19',
      'ai_quota_count': 'bukan-angka',
    });
    expect(await build().remaining(), 2);
  });
}
