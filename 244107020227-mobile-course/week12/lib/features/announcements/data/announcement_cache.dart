import '../domain/entities/announcement.dart';

class CachedAnnouncements {
  const CachedAnnouncements({required this.items, required this.savedAt});

  final List<Announcement> items;
  final DateTime savedAt;
}

abstract class AnnouncementCache {
  Future<CachedAnnouncements?> read();
  Future<void> write(List<Announcement> items, DateTime savedAt);
}
