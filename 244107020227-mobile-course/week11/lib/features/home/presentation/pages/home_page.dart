import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/format.dart';
import '../../../announcements/presentation/widgets/announcements_section.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/widgets/chat_entry_button.dart';
import '../../../notifications/presentation/providers/push_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(pushControllerProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tidak ada ref.watch di sini: perubahan token FCM hanya membangun ulang
    // _FcmTokenTile, bukan seluruh Scaffold dan daftar pengumuman.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          const ChatEntryButton(),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Column(
        children: [
          _FcmTokenTile(),
          Divider(height: 1),
          Expanded(child: AnnouncementsSection()),
        ],
      ),
    );
  }
}

class _FcmTokenTile extends ConsumerWidget {
  const _FcmTokenTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(pushControllerProvider);
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('FCM token (debug)'),
      subtitle: Text(maskToken(token)),
    );
  }
}
