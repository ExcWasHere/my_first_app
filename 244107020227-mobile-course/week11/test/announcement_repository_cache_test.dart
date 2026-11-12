import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/announcements/data/announcement_cache.dart';
import 'package:week10/features/announcements/data/announcement_remote_data_source.dart';
import 'package:week10/features/announcements/data/announcement_repository_impl.dart';
import 'package:week10/features/announcements/domain/entities/announcement.dart';

const _fresh = [
  Announcement(id: '1', title: 'Baru 1', body: 'b1'),
  Announcement(id: '2', title: 'Baru 2', body: 'b2'),
];
const _old = [Announcement(id: '9', title: 'Lama 9', body: 'b9')];

class _Remote implements AnnouncementRemoteDataSource {
  _Remote({this.fail = false});

  bool fail;
  int fetchAllCalls = 0;
  int fetchOneCalls = 0;

  @override
  Future<List<Announcement>> fetchAll() async {
    fetchAllCalls++;
    if (fail) throw Exception('offline');
    return _fresh;
  }

  @override
  Future<Announcement> fetchOne(String id) async {
    fetchOneCalls++;
    if (fail) throw Exception('offline');
    return Announcement(id: id, title: 'Remote $id', body: 'r');
  }
}

class _MemoryCache implements AnnouncementCache {
  CachedAnnouncements? stored;

  @override
  Future<CachedAnnouncements?> read() async => stored;

  @override
  Future<void> write(List<Announcement> items, DateTime savedAt) async {
    stored = CachedAnnouncements(items: items, savedAt: savedAt);
  }
}

void main() {
  final t0 = DateTime(2026, 11, 12, 10);
  var clock = t0;
  late _Remote remote;
  late _MemoryCache cache;

  AnnouncementRepositoryImpl build() => AnnouncementRepositoryImpl(
        remote: remote,
        cache: cache,
        ttl: const Duration(minutes: 5),
        now: () => clock,
      );

  setUp(() {
    clock = t0;
    remote = _Remote();
    cache = _MemoryCache();
  });

  test('cache kosong: ambil dari API lalu simpan ke cache', () async {
    final result = await build().fetchAnnouncements();
    expect(result.items, _fresh);
    expect(result.failure, isNull);
    expect(remote.fetchAllCalls, 1);
    expect(cache.stored?.items, _fresh);
  });

  test('cache masih segar: tidak ada request ke API', () async {
    cache.stored = CachedAnnouncements(items: _old, savedAt: t0);
    clock = t0.add(const Duration(minutes: 4));
    final result = await build().fetchAnnouncements();
    expect(result.items, _old);
    expect(remote.fetchAllCalls, 0);
  });

  test('cache kedaluwarsa: ambil ulang dan perbarui cache', () async {
    cache.stored = CachedAnnouncements(items: _old, savedAt: t0);
    clock = t0.add(const Duration(minutes: 6));
    final result = await build().fetchAnnouncements();
    expect(result.items, _fresh);
    expect(remote.fetchAllCalls, 1);
    expect(cache.stored?.items, _fresh);
    expect(cache.stored?.savedAt, clock);
  });

  test('API gagal tetapi ada cache lama: pakai cache lama', () async {
    cache.stored = CachedAnnouncements(items: _old, savedAt: t0);
    clock = t0.add(const Duration(hours: 1));
    remote.fail = true;
    final result = await build().fetchAnnouncements();
    expect(result.items, _old);
    expect(result.failure, isNull);
  });

  test('API gagal dan tidak ada cache: kembalikan NetworkFailure', () async {
    remote.fail = true;
    final result = await build().fetchAnnouncements();
    expect(result.items, isEmpty);
    expect(result.failure, isA<NetworkFailure>());
  });

  test('detail yang ada di cache tidak memicu request', () async {
    cache.stored = CachedAnnouncements(items: _old, savedAt: t0);
    final result = await build().fetchAnnouncement('9');
    expect(result.item?.title, 'Lama 9');
    expect(remote.fetchOneCalls, 0);
  });

  test('detail yang tidak ada di cache diambil dari API', () async {
    final result = await build().fetchAnnouncement('77');
    expect(result.item?.title, 'Remote 77');
    expect(remote.fetchOneCalls, 1);
  });
}
