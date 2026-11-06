import 'package:flutter_test/flutter_test.dart';
import 'package:week10/features/chat/data/sse_parser.dart';

void main() {
  test('mengambil teks dari delta.content', () {
    const line = 'data: {"choices":[{"delta":{"content":"Halo"}}]}';
    expect(parseSseDelta(line), 'Halo');
  });

  test('[DONE], baris kosong, dan komentar menghasilkan null', () {
    expect(parseSseDelta('data: [DONE]'), isNull);
    expect(parseSseDelta(''), isNull);
    expect(parseSseDelta(': keep-alive'), isNull);
  });

  test('delta tanpa teks atau teks kosong menghasilkan null', () {
    expect(parseSseDelta('data: {"choices":[{"delta":{}}]}'), isNull);
    const empty = 'data: {"choices":[{"delta":{"role":"assistant","content":""}}]}';
    expect(parseSseDelta(empty), isNull);
  });

  test('JSON rusak tidak melempar error', () {
    expect(parseSseDelta('data: {bukan json'), isNull);
    expect(parseSseDelta('data: {"choices":[]}'), isNull);
  });
}
