import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/chat/data/groq_chat_repository.dart';
import 'package:week10/features/chat/domain/entities/chat_message.dart';
import 'support/chat_fakes.dart';

class _SseAdapter implements HttpClientAdapter {
  _SseAdapter({this.lines = const [], this.statusCode = 200});

  final List<String> lines;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (statusCode != 200) {
      return ResponseBody.fromString('{}', statusCode, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody(
      Stream.fromIterable([
        for (final line in lines) utf8.encode('$line\n'),
      ]),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

GroqChatRepository _repo(_SseAdapter adapter, {String? key = 'gsk_uji'}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://contoh.test'))
    ..httpClientAdapter = adapter;
  return GroqChatRepository(settings: FakeSettings(key), dio: dio);
}

Future<List<String>> _ask(GroqChatRepository repo) => repo
    .streamCompletion([const ChatMessage(role: ChatRole.user, content: 'Halo')])
    .toList();

void main() {
  test('potongan delta dari SSE dialirkan berurutan', () async {
    final adapter = _SseAdapter(lines: [
      'data: {"choices":[{"delta":{"content":"Halo"}}]}',
      ': keep-alive',
      'data: {"choices":[{"delta":{"content":" dunia"}}]}',
      'data: [DONE]',
    ]);

    expect(await _ask(_repo(adapter)), ['Halo', ' dunia']);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer gsk_uji');
  });

  test('API key kosong gagal sebelum memanggil jaringan', () async {
    final adapter = _SseAdapter();

    await expectLater(
      _ask(_repo(adapter, key: null)),
      throwsA(isA<ValidationFailure>()),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('status 401 dan 429 dipetakan ke pesan yang tepat', () async {
    await expectLater(
      _ask(_repo(_SseAdapter(statusCode: 401))),
      throwsA(isA<UnauthorizedFailure>()),
    );
    await expectLater(
      _ask(_repo(_SseAdapter(statusCode: 429))),
      throwsA(
        isA<NetworkFailure>().having(
          (f) => f.message,
          'message',
          contains('Batas permintaan'),
        ),
      ),
    );
  });

  test('status 500 menjadi NetworkFailure layanan bermasalah', () async {
    await expectLater(
      _ask(_repo(_SseAdapter(statusCode: 500))),
      throwsA(
        isA<NetworkFailure>().having(
          (f) => f.message,
          'message',
          contains('bermasalah'),
        ),
      ),
    );
  });
}
