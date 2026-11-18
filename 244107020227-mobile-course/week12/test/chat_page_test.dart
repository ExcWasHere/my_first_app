import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/announcements/domain/entities/announcement.dart';
import 'package:week10/features/announcements/presentation/providers/announcements_providers.dart';
import 'package:week10/features/chat/presentation/pages/chat_page.dart';
import 'package:week10/features/chat/presentation/providers/chat_providers.dart';
import 'support/chat_fakes.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeChat chat,
  String? key = 'gsk_test',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chat),
        aiSettingsRepositoryProvider.overrideWithValue(FakeSettings(key)),
        usageQuotaRepositoryProvider.overrideWithValue(FakeQuota(5)),
        announcementsProvider.overrideWith(
          (ref) async => const [
            Announcement(id: '1', title: 'Jadwal UTS', body: 'UTS dimulai Senin'),
          ],
        ),
      ],
      child: const MaterialApp(home: ChatPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan pertanyaan dan jawaban AI', (tester) async {
    await _pump(tester, chat: FakeChat(['UTS dimulai ', 'Senin.']));
    await _ask(tester, 'Kapan UTS?');

    expect(find.text('Kapan UTS?'), findsOneWidget);
    expect(find.text('UTS dimulai Senin.'), findsOneWidget);
  });

  testWidgets('layanan error: banner dan jawaban cadangan lokal', (tester) async {
    final chat = FakeChat(
      const [],
      error: const NetworkFailure('Layanan AI sedang bermasalah.'),
    );
    await _pump(tester, chat: chat);
    await _ask(tester, 'Kapan UTS?');

    expect(find.text('Layanan AI sedang bermasalah.'), findsOneWidget);
    expect(find.textContaining('Layanan AI sedang tidak tersedia'), findsOneWidget);
    expect(find.textContaining('Jadwal UTS'), findsOneWidget);
  });

  testWidgets('tanpa API key menampilkan banner pengaturan', (tester) async {
    await _pump(tester, chat: FakeChat(const []), key: null);

    expect(find.textContaining('API key belum diatur'), findsOneWidget);
  });

  testWidgets('tombol coba lagi mengirim ulang pertanyaan terakhir',
      (tester) async {
    final chat = FakeChat(
      const [],
      error: const NetworkFailure('Layanan AI sedang bermasalah.'),
    );
    await _pump(tester, chat: chat);
    await _ask(tester, 'Kapan UTS?');
    expect(chat.calls, 1);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(chat.calls, 2);
    expect(find.text('Kapan UTS?'), findsOneWidget);
    expect(find.text('Layanan AI sedang bermasalah.'), findsOneWidget);
  });

  testWidgets('tombol hapus percakapan mengosongkan daftar pesan',
      (tester) async {
    await _pump(tester, chat: FakeChat(['UTS dimulai Senin.']));
    await _ask(tester, 'Kapan UTS?');

    await tester.tap(find.byTooltip('Hapus percakapan'));
    await tester.pumpAndSettle();

    expect(find.text('Kapan UTS?'), findsNothing);
    expect(find.text('UTS dimulai Senin.'), findsNothing);
    expect(find.textContaining('Tanyakan sesuatu'), findsOneWidget);
  });

  testWidgets('menyimpan API key lewat dialog menghilangkan banner',
      (tester) async {
    final settings = FakeSettings(null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(FakeChat(const [])),
          aiSettingsRepositoryProvider.overrideWithValue(settings),
          usageQuotaRepositoryProvider.overrideWithValue(FakeQuota(5)),
          announcementsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: ChatPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('API key belum diatur'), findsOneWidget);

    await tester.tap(find.byTooltip('Atur API key'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'API key'),
      'gsk_baru',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(settings.key, 'gsk_baru');
    expect(find.textContaining('API key belum diatur'), findsNothing);
  });

  testWidgets('menghapus API key lewat dialog memunculkan banner lagi',
      (tester) async {
    final settings = FakeSettings('gsk_lama');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(FakeChat(const [])),
          aiSettingsRepositoryProvider.overrideWithValue(settings),
          usageQuotaRepositoryProvider.overrideWithValue(FakeQuota(5)),
          announcementsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: ChatPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('API key belum diatur'), findsNothing);

    await tester.tap(find.byTooltip('Atur API key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus key'));
    await tester.pumpAndSettle();

    expect(settings.key, isNull);
    expect(find.textContaining('API key belum diatur'), findsOneWidget);
  });
}
