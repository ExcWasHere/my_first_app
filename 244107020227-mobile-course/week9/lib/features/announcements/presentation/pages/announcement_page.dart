import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../providers/announcements_providers.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman $id'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(messageOf(e))),
        data: (a) => Center(child: Text(a.body)),
      ),
    );
  }
}
