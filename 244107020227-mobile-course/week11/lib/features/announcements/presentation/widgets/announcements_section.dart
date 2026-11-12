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
class AnnouncementsSection extends ConsumerWidget {
  const AnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(announcementSearchQueryProvider);
    final announcements = ref.watch(filteredAnnouncementsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AnnouncementSearchField(),
        ...announcements.when<List<Widget>>(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (e, _) => [ListTile(title: Text(messageOf(e)))],
          data: (items) => _resultTiles(context, items, query),
        ),
      ],
    );
  }

  List<Widget> _resultTiles(
    BuildContext context,
    List<Announcement> items,
    String query,
  ) {
    if (items.isEmpty) return [AnnouncementEmptyState(query: query)];
    return [
      for (final a in items)
        ListTile(
          leading: const Icon(Icons.campaign),
          title: Text(a.title),
          onTap: () => context.go(AppRoutes.announcement(a.id)),
        ),
    ];
  }
}
