import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _setupPush();
  }

  Future<void> _setupPush() async {
    final granted = await requestNotificationPermission();
    if (!granted) return;

    await initFcmToken(onToken: (token) async {
      fcmTokenNotifier.value = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: fcmTokenNotifier,
            builder: (_, token, _) => ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('FCM token (debug)'),
              subtitle: Text(
                token == null ? 'belum ada' : '${token.substring(0, 12)}...',
              ),
            ),
          ),
          const Divider(),
          for (final id in ['1', '2', '3'])
            ListTile(
              leading: const Icon(Icons.campaign),
              title: Text('Pengumuman $id'),
              onTap: () => context.go('/pengumuman/$id'),
            ),
        ],
      ),
    );
  }
}