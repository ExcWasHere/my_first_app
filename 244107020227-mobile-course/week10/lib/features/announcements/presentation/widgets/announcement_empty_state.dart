import 'package:flutter/material.dart';

class AnnouncementEmptyState extends StatelessWidget {
  const AnnouncementEmptyState({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    final message = q.isEmpty
        ? 'Belum ada pengumuman.'
        : 'Tidak ada pengumuman untuk "$q".';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
