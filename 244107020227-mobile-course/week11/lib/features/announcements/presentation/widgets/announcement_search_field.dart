import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/announcements_providers.dart';

class AnnouncementSearchField extends ConsumerStatefulWidget {
  const AnnouncementSearchField({super.key});

  @override
  ConsumerState<AnnouncementSearchField> createState() =>
      _AnnouncementSearchFieldState();
}

class _AnnouncementSearchFieldState
    extends ConsumerState<AnnouncementSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Query disimpan di provider, jadi field harus ikut nilai terakhirnya
    // saat widget dibangun ulang (mis. kembali dari halaman detail).
    _controller = TextEditingController(
      text: ref.read(announcementSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = ref.watch(announcementSearchQueryProvider).isNotEmpty;
    final notifier = ref.read(announcementSearchQueryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: notifier.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari judul pengumuman',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    notifier.clear();
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
