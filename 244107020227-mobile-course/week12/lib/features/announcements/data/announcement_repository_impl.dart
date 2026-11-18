import '../../../core/failures.dart';
import '../domain/entities/announcement.dart';
import '../domain/repositories/announcement_repository.dart';
import 'announcement_cache.dart';
import 'announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({
    required this.remote,
    required this.cache,
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AnnouncementRemoteDataSource remote;
  final AnnouncementCache cache;
  final Duration ttl;
  final DateTime Function() _now;

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    final cached = await cache.read();
    if (cached != null && _now().difference(cached.savedAt) < ttl) {
      return (items: cached.items, failure: null);
    }
    try {
      final fresh = await remote.fetchAll();
      await cache.write(fresh, _now());
      return (items: fresh, failure: null);
    } catch (_) {
      if (cached != null) return (items: cached.items, failure: null);
      return (
        items: const <Announcement>[],
        failure: const NetworkFailure('Tidak ada koneksi internet.'),
      );
    }
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) async {
    final cached = await cache.read();
    if (cached != null) {
      for (final a in cached.items) {
        if (a.id == id) return (item: a, failure: null);
      }
    }
    try {
      return (item: await remote.fetchOne(id), failure: null);
    } catch (_) {
      return (
        item: null,
        failure: const NetworkFailure('Tidak ada koneksi internet.'),
      );
    }
  }
}
