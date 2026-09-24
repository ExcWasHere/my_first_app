import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  final int postId;
  final Post? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Post> postAsync = initialPost != null
        ? AsyncData(initialPost!)
        : ref.watch(postByIdProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
      ),
      body: postAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (initialPost == null)
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(
                        postByIdProvider(postId),
                      );
                    },
                    child: const Text('Coba lagi'),
                  ),
              ],
            ),
          ),
        ),
        data: (post) {
          final commentsAsync =
              ref.watch(commentsProvider(post.id));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                post.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              const SizedBox(height: 16),

              Text(
                post.body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),

              const SizedBox(height: 28),

              const Divider(),

              const SizedBox(height: 16),

              Text(
                'Comments',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

                error: (error, _) => Column(
                  children: [
                    Text(
                      friendlyErrorMessage(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(
                          commentsProvider(post.id),
                        );
                      },
                      child: const Text(
                        'Muat ulang komentar',
                      ),
                    ),
                  ],
                ),

                data: (comments) {
                  if (comments.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Belum ada komentar.',
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(),
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(comment.name),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(comment.body),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}