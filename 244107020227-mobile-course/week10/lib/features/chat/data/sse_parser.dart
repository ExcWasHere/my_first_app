import 'dart:convert';

String? parseSseDelta(String line) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('data:')) return null;
  final payload = trimmed.substring(5).trim();
  if (payload.isEmpty || payload == '[DONE]') return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final delta = first['delta'];
    if (delta is! Map) return null;
    final content = delta['content'];
    return content is String && content.isNotEmpty ? content : null;
  } on FormatException {
    return null;
  }
}
