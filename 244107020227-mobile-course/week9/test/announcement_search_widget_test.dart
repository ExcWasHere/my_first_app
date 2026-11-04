import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week9/core/failures.dart';
import 'package:week9/features/announcements/domain/entities/announcement.dart';
import 'package:week9/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:week9/features/announcements/presentation/providers/announcements_providers.dart';
import 'package:week9/features/announcements/presentation/widgets/announcements_section.dart';

class _FakeRepository implements AnnouncementRepository {
  const _FakeRepository();

  static const _items = [
    Announcement(id: '1', title: 'Jadwal UTS Genap', body: 'isi 1'),
    Announcement(id: '2', title: 'Beasiswa Prestasi', body: 'isi 2'),
  ];

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    return (items: _items, failure: null);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) {
    throw UnimplementedError();
  }
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      announcementRepositoryProvider.overrideWithValue(
        const _FakeRepository(),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: AnnouncementsSection()),
      ),
    ),
  );
}

void main() {
  testWidgets('tanpa query, semua pengumuman tampil', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Jadwal UTS Genap'), findsOneWidget);
    expect(find.text('Beasiswa Prestasi'), findsOneWidget);
  });

  testWidgets('query cocok menyaring daftar', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'beasiswa');
    await tester.pump();

    expect(find.text('Beasiswa Prestasi'), findsOneWidget);
    expect(find.text('Jadwal UTS Genap'), findsNothing);
  });

  testWidgets('query tak cocok menampilkan empty state', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Tidak ada pengumuman untuk "zzz".'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('tombol hapus mengembalikan seluruh daftar', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump();

    expect(find.text('Jadwal UTS Genap'), findsOneWidget);
    expect(find.text('Beasiswa Prestasi'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsNothing);
  });
}
