import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/failures.dart';
import '../../../../core/format.dart';
import '../../../../routes.dart';
import '../../../announcements/presentation/providers/announcements_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
    final token = ref.watch(pushControllerProvider);
    final announcements = ref.watch(announcementsProvider);

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
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('FCM token (debug)'),
            subtitle: Text(maskToken(token)),
          ),
          const Divider(),
          ...announcements.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [ListTile(title: Text(messageOf(e)))],
            data: (items) => [
              for (final a in items)
                ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(a.title),
                  onTap: () => context.go(AppRoutes.announcement(a.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
