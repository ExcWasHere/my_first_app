import '../domain/entities/announcement.dart';

abstract class AnnouncementRemoteDataSource {
  Future<List<Announcement>> fetchAll();
  Future<Announcement> fetchOne(String id);
}

class FakeAnnouncementApi implements AnnouncementRemoteDataSource {
  const FakeAnnouncementApi();
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
  Future<List<Announcement>> fetchAll() async {
    await Future<void>.delayed(_latency);
    return [for (var i = 1; i <= totalCount; i++) _build('$i')];
  }

  @override
  Future<Announcement> fetchOne(String id) async {
    await Future<void>.delayed(_latency);
    return _build(id);
  }
}
