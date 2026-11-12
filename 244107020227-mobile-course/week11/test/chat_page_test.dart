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
}
