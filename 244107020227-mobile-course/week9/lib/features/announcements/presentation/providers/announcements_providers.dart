import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';
import '../../domain/usecases/search_announcements.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepositoryImpl(),
);

final getAnnouncementsProvider = Provider<GetAnnouncements>(
  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)),
);

final searchAnnouncementsProvider = Provider<SearchAnnouncements>(
  (ref) => const SearchAnnouncements(),
);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  final failure = result.failure;
  if (failure != null) throw failure;
  return result.items;
});

final announcementProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final result =
      await ref.watch(announcementRepositoryProvider).fetchAnnouncement(id);
  final failure = result.failure;
  if (failure != null) throw failure;
  return result.item!;
});

/// State saja: menyimpan kata kunci pencarian yang sedang diketik.
class AnnouncementSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final announcementSearchQueryProvider =
    NotifierProvider<AnnouncementSearchQuery, String>(
  AnnouncementSearchQuery.new,
);

/// Daftar pengumuman setelah disaring use case [SearchAnnouncements].
final filteredAnnouncementsProvider =
    Provider<AsyncValue<List<Announcement>>>((ref) {
  final query = ref.watch(announcementSearchQueryProvider);
  final search = ref.watch(searchAnnouncementsProvider);
  return ref
      .watch(announcementsProvider)
      .whenData((items) => search.call(items, query));
});
