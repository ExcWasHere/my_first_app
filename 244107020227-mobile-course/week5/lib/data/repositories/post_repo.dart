import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio, {Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    final response = await _dio.get<List>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  Future<Post> fetchPostById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$id'),
          statusCode: 404,
        ),
      );
    }
    return Post.fromJson(data);
  }

  // --- Praktikum 3: cache-first read ---

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(payload);
    }).toList();
  }

  Future<void> _cachePosts(List<Post> posts) async {
    final db = await _openDb();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Fetch dari network lalu simpan ke cache; dipanggil di background.
  Future<void> refreshPostsInBackground() async {
    try {
      final posts = await fetchPosts();
      await _cachePosts(posts);
    } catch (_) {
      // Gagal refresh (misal offline) — cache lama tetap dipakai.
    }
  }

  /// Sesuai contoh modul: balikin cache dulu, refresh di background.
  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts();
    // ignore: unawaited_futures
    refreshPostsInBackground();
    return cached;
  }
}