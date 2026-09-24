import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week4/data/models/post.dart';
import 'package:week4/data/network_errors.dart';
import 'package:week4/data/providers.dart';
import 'package:week4/data/repositories/post_repo.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository({
    this.items,
    this.throwError = false,
  }) : super(Dio());

  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '/posts',
        ),
        type: DioExceptionType.connectionError,
      );
    }

    return items ?? const [];
  }

  @override
  Future<List<Post>> fetchPostsPage({
    required int page,
    int limit = 10,
  }) {
    return fetchPosts();
  }
}

void main() {
  test(
    'fromJson aman terhadap field yang hilang',
    () {
      final post = Post.fromJson({
        'id': 7,
      });

      expect(post.id, 7);
      expect(post.title, '');
      expect(post.userId, 0);
      expect(post.body, '');
    },
  );

  test(
    'friendlyErrorMessage untuk connection error',
    () {
      final err = DioException(
        requestOptions: RequestOptions(
          path: '/posts',
        ),
        type: DioExceptionType.connectionError,
      );

      expect(
        friendlyErrorMessage(err),
        contains('terhubung'),
      );
    },
  );

  test(
    'provider sukses dengan repository palsu',
    () async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(
              items: [
                const Post(
                  userId: 1,
                  id: 1,
                  title: 'Tes',
                  body: 'Isi',
                ),
              ],
            ),
          ),
        ],
      );

      addTearDown(container.dispose);

      final posts =
          await readPostsOnce(container);

      expect(posts.length, 1);
      expect(posts.first.title, 'Tes');
    },
  );

  test(
    'provider error dengan repository palsu',
    () async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(
              throwError: true,
            ),
          ),
        ],
      );

      addTearDown(container.dispose);

      final err =
          await readPostsErrorOnce(container);

      expect(err, isA<DioException>());

      expect(
        friendlyErrorMessage(err!),
        contains('terhubung'),
      );
    },
  );
}