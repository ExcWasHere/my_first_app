import '../../../announcements/domain/entities/announcement.dart';

class BuildOfflineAnswer {
  const BuildOfflineAnswer({this.limit = 3});

  final int limit;

  String call(List<Announcement> announcements) {
    if (announcements.isEmpty) {
      return 'Layanan AI sedang tidak tersedia dan belum ada data '
          'pengumuman lokal.';
    }
    final titles = announcements.take(limit).map((a) => '- ${a.title}');
    return 'Layanan AI sedang tidak tersedia. Pengumuman terbaru:\n'
        '${titles.join('\n')}';
  }
}
