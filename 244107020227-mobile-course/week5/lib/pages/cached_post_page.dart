import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../post_tile.dart';

class CachedPostsPage extends ConsumerWidget {
  const CachedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsCacheFirstProvider);
    final offline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (Cache-First)'),
        actions: [
          IconButton(
            tooltip: offline ? 'Nyalakan koneksi' : 'Simulasi offline',
            icon: Icon(offline ? Icons.cloud_off : Icons.cloud_queue),
            onPressed: () =>
                ref.read(forceOfflineProvider.notifier).state = !offline,
          ),
        ],
      ),
      body: Column(
        children: [
          if (offline)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Mode offline (simulasi): menampilkan data dari cache lokal.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gagal memuat posts: $error'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(postsCacheFirstProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Cache masih kosong. Buka halaman ini sekali saat '
                        'online agar data tersimpan.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(postsCacheFirstProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) =>
                        PostTile(post: posts[index], showBody: true),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}