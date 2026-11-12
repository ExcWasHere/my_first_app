import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../domain/entities/announcement.dart';
import 'announcement_cache.dart';

class HiveAnnouncementCache implements AnnouncementCache {
  HiveAnnouncementCache();

  static const _boxName = 'announcement_cache';
  static const _key = 'list';
  static Future<Box<String>?>? _opening;

  Future<Box<String>?> _box() => _opening ??= _open();

  Future<Box<String>?> _open() async {
    try {
      await Hive.initFlutter();
      return await Hive.openBox<String>(_boxName);
    } catch (e) {
      debugPrint('CACHE gagal membuka Hive: $e');
      return null;
    }
  }

  @override
  Future<CachedAnnouncements?> read() async {
    try {
      final raw = (await _box())?.get(_key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = [
        for (final e in map['items'] as List)
          Announcement(
            id: (e as Map<String, dynamic>)['id'] as String,
            title: e['title'] as String,
            body: e['body'] as String,
          ),
      ];
      return CachedAnnouncements(
        items: items,
        savedAt: DateTime.parse(map['savedAt'] as String),
      );
    } catch (e) {
      debugPrint('CACHE gagal membaca: $e');
      return null;
    }
  }

  @override
  Future<void> write(List<Announcement> items, DateTime savedAt) async {
    try {
      final data = jsonEncode({
        'savedAt': savedAt.toUtc().toIso8601String(),
        'items': [
          for (final a in items) {'id': a.id, 'title': a.title, 'body': a.body},
        ],
      });
      await (await _box())?.put(_key, data);
    } catch (e) {
      debugPrint('CACHE gagal menulis: $e');
    }
  }
}
