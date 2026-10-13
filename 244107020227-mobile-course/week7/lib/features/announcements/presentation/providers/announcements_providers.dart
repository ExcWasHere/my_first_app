import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepositoryImpl(),
);

final getAnnouncementsProvider = Provider<GetAnnouncements>(
  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)),
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
