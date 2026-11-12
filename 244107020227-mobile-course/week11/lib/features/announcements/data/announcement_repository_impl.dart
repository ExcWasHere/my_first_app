import '../../../core/failures.dart';
import '../domain/entities/announcement.dart';
import '../domain/repositories/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();
  static const totalCount = 200;
  static const _latency = Duration(milliseconds: 600);

  static const _topics = [
    'Jadwal UTS Genap',
    'Beasiswa Prestasi',
    'Pendaftaran Wisuda',
    'Libur Akademik',
    'Jadwal Praktikum',
    'Seminar Nasional',
    'Lomba Gemastik',
    'Magang Industri',
  ];

  Announcement _build(String id) {
    final n = int.tryParse(id) ?? 1;
    final topic = _topics[n % _topics.length];
    return Announcement(
      id: id,
      title: '$topic #$n',
      body: 'Detail pengumuman $topic nomor $n.',
    );
  }

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    await Future<void>.delayed(_latency);
    final items = [
      for (var i = 1; i <= totalCount; i++) _build('$i'),
    ];
    return (items: items, failure: null);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) async {
    await Future<void>.delayed(_latency);
    return (item: _build(id), failure: null);
  }
}