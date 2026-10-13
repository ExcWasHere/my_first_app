import 'package:flutter_test/flutter_test.dart';
import 'package:week6/core/failures.dart';
import 'package:week6/features/announcements/domain/entities/announcement.dart';
import 'package:week6/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:week6/features/announcements/domain/usecases/get_announcements.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});
  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    if (fail) {
      return (
        items: const <Announcement>[],
        failure: const NetworkFailure('Tidak ada koneksi internet.'),
      );
    }
    return (items: items, failure: null);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) {
    throw UnimplementedError();
  }
}

void main() {
  test('GetAnnouncements meneruskan daftar dari repository', () async {
    final repo = FakeAnnouncementRepository(items: const [
      Announcement(id: '1', title: 'Pengumuman 1', body: 'isi'),
    ]);
    final result = await GetAnnouncements(repo).call();
    expect(result.failure, isNull);
    expect(result.items.single.title, 'Pengumuman 1');
  });

  test('GetAnnouncements meneruskan failure tanpa melempar', () async {
    final result =
        await GetAnnouncements(FakeAnnouncementRepository(fail: true)).call();
    expect(result.failure, isA<NetworkFailure>());
    expect(result.items, isEmpty);
  });
}
