import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcements_providers.dart';
import 'announcement_empty_state.dart';
import 'announcement_search_field.dart';

/// Kolom pencarian + daftar pengumuman + empty state.
///
/// Memakai [Expanded] sehingga harus ditaruh di dalam parent yang tinggi-nya
/// terbatas (mis. `Column` / `Scaffold.body`). Daftar dibangun malas lewat
/// `ListView.builder`: hanya item yang tampil di layar yang dibuat.
class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AnnouncementSearchField(),
        Expanded(child: _AnnouncementList()),
      ],
    );
  }
}

class _AnnouncementList extends ConsumerWidget {
  const _AnnouncementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(filteredAnnouncementsProvider);
    return announcements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListTile(title: Text(messageOf(e))),
      data: (items) {
        if (items.isEmpty) {
          final query = ref.watch(announcementSearchQueryProvider);
          return AnnouncementEmptyState(query: query);
        }
        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: items.length,
          itemBuilder: (_, i) => _AnnouncementTile(announcement: items[i]),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(announcement.id),
      leading: const Icon(Icons.campaign),
      title: Text(announcement.title),
      // push (bukan go): halaman beranda tetap hidup di bawah halaman detail.
      onTap: () => context.push(AppRoutes.announcement(announcement.id)),
    );
  }
}
