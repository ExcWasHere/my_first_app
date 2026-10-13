import '../../../core/failures.dart';
import '../domain/entities/announcement.dart';
import '../domain/repositories/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();

  static const _ids = ['1', '2', '3'];

  Announcement _build(String id) => Announcement(
        id: id,
        title: 'Pengumuman $id',
        body: 'Detail pengumuman dengan id: $id',
      );

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    return (items: _ids.map(_build).toList(), failure: null);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) async {
    return (item: _build(id), failure: null);
  }
}
