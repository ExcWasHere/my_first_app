import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'local/note.dart';
import 'repositories/post_repo.dart';
import 'repositories/comment_repo.dart';
import 'repositories/note_repo.dart';
import 'sync.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
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

final forceOfflineProvider = StateProvider<bool>((ref) => false);

final postCacheServiceProvider = Provider<PostCacheService>(
  (ref) => PostCacheService(ref.watch(dioProvider)),
);

final postsCacheFirstProvider =
    AsyncNotifierProvider<PostsCacheFirstNotifier, List<Post>>(
  PostsCacheFirstNotifier.new,
  retry: (retryCount, error) => null,
);

class PostsCacheFirstNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final cache = ref.watch(postCacheServiceProvider);
    final offline = ref.watch(forceOfflineProvider);

    final cached = await cache.readCachedPosts();
    if (offline) return cached;

    if (cached.isEmpty) {
      await cache.refreshPostsInBackground();
      return cache.readCachedPosts();
    }

    unawaited(_refreshInBackground(cache));
    return cached;
  }

  Future<void> _refreshInBackground(PostCacheService cache) async {
    final updated = await cache.refreshPostsInBackground();
    if (!updated || !ref.mounted) return;
    final fresh = await cache.readCachedPosts();
    if (!ref.mounted) return;
    state = AsyncData(fresh);
  }

  Future<void> refresh() async {
    if (ref.read(forceOfflineProvider)) return;
    final cache = ref.read(postCacheServiceProvider);
    await cache.refreshPostsInBackground();
    if (!ref.mounted) return;
    final fresh = await cache.readCachedPosts();
    if (!ref.mounted) return;
    state = AsyncData(fresh);
  }
}

final noteRepositoryProvider = Provider((ref) => NoteRepository());
final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repository = ref.watch(noteRepositoryProvider);
    return repository.fetchNotes();
  }

  Future<void> addNote({required String title, String body = ''}) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.addNote(title: title, body: body);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(id);
    ref.invalidate(noteByIdProvider);
    ref.invalidateSelf();
  }

  Future<int> sync() async {
    if (ref.read(forceOfflineProvider)) throw const OfflineException();
    if (ref.read(syncingProvider)) return 0; // cegah tap ganda

    ref.read(syncingProvider.notifier).state = true;
    try {
      final synced = await syncNotes(ref.read(noteRepositoryProvider));
      ref.invalidate(noteByIdProvider);
      ref.invalidateSelf();
      return synced;
    } finally {
      ref.read(syncingProvider.notifier).state = false;
    }
  }
}

final syncingProvider = StateProvider<bool>((ref) => false);
final dirtyCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  return notes.where((n) => n.dirty).length;
});

final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.fetchNoteById(id);
});