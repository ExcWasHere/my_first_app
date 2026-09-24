import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'repositories/post_repo.dart';
import 'repositories/comment_repo.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        retry: (retryCount, error) => null);
final postByIdProvider = FutureProvider.family<Post, int>((ref, id) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPostById(id);
});

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);
  final int postId;

  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
  CommentsNotifier.new,
  retry: (retryCount, error) => null,
);

Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}