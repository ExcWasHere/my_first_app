import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/chat/domain/entities/chat_message.dart';
import 'package:week10/features/chat/domain/usecases/send_chat_message.dart';
import 'support/chat_fakes.dart';

SendChatMessage _useCase(FakeChat chat, FakeSettings s, FakeQuota q) =>
    SendChatMessage(chat: chat, settings: s, quota: q);

Stream<String> _run(SendChatMessage uc, String question) =>
    uc(announcements: const [], history: const [], question: question);

void main() {
  test('sukses: potongan jawaban mengalir dan kuota terpakai satu', () async {
    final chat = FakeChat(['Halo ', 'dunia']);
    final quota = FakeQuota(5);
    final uc = _useCase(chat, FakeSettings('gsk_test'), quota);

    final chunks = await _run(uc, 'Kapan UTS?').toList();

    expect(chunks.join(), 'Halo dunia');
    expect(quota.left, 4);
    expect(chat.lastMessages!.first.role, ChatRole.system);
    expect(chat.lastMessages!.last.content, 'Kapan UTS?');
  });

  test('gagal: pertanyaan kosong tidak memanggil AI', () async {
    final chat = FakeChat(['x']);
    final uc = _useCase(chat, FakeSettings('gsk_test'), FakeQuota(5));

    await expectLater(
      _run(uc, '   ').toList(),
      throwsA(isA<ValidationFailure>()),
    );
    expect(chat.calls, 0);
  });

  test('gagal: pertanyaan lebih dari 500 karakter', () async {
    final chat = FakeChat(['x']);
    final uc = _useCase(chat, FakeSettings('gsk_test'), FakeQuota(5));

    await expectLater(
      _run(uc, 'a' * 501).toList(),
      throwsA(isA<ValidationFailure>()),
    );
    expect(chat.calls, 0);
  });

  test('gagal: API key belum diatur, kuota tidak terpakai', () async {
    final chat = FakeChat(['x']);
    final quota = FakeQuota(5);
    final uc = _useCase(chat, FakeSettings(null), quota);

    await expectLater(
      _run(uc, 'halo').toList(),
      throwsA(isA<ValidationFailure>()),
    );
    expect(chat.calls, 0);
    expect(quota.left, 5);
  });

  test('gagal: kuota harian habis', () async {
    final chat = FakeChat(['x']);
    final uc = _useCase(chat, FakeSettings('gsk_test'), FakeQuota(0));

    await expectLater(
      _run(uc, 'halo').toList(),
      throwsA(isA<LocalFailure>()),
    );
    expect(chat.calls, 0);
  });
}
