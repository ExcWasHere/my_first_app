import 'dart:convert';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repo.dart';

class OfflineException implements Exception {
  const OfflineException([
    this.message = 'Mode offline aktif. Sinkronisasi ditunda.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class PostCacheService {
  PostCacheService(this._dio, {Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(json);
    }).toList();
  }

  Future<bool> refreshPostsInBackground() async {
    try {
      final response = await _dio.get<List<dynamic>>('/posts');
      final items = response.data ?? const <dynamic>[];
      final db = await _openDb();
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.delete('cached_posts');
        final batch = txn.batch();
        for (final item in items) {
          final map = Map<String, dynamic>.from(item as Map);
          batch.insert(
            'cached_posts',
            {
              'id': map['id'],
              'payload': jsonEncode(map),
              'cached_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      return true;
    } catch (e, st) {
      dev.log(
        'Refresh cache posts gagal, pakai cache lama',
        name: 'PostCacheService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyNotes = await repo.fetchDirtyNotes();
  if (dirtyNotes.isEmpty) return 0;

  await Future<void>.delayed(const Duration(seconds: 1));

  await repo.markSynced([
    for (final note in dirtyNotes)
      if (note.id != null) note.id!,
  ]);
  return dirtyNotes.length;
}