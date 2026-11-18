import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/failures.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/ai_settings_repository.dart';
import '../domain/repositories/chat_repository.dart';
import 'ai_config.dart';
import 'sse_parser.dart';

class GroqChatRepository implements ChatRepository {
  GroqChatRepository({required this.settings, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final AiSettingsRepository settings;
  final Dio _dio;

  @override
  Stream<String> streamCompletion(List<ChatMessage> messages) async* {
    final key = await settings.readApiKey();
    if (key == null || key.isEmpty) {
      throw const ValidationFailure('API key belum diatur.');
    }
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: _body(messages),
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $key',
            'Accept': 'text/event-stream',
          },
        ),
      );
      final lines = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        final delta = parseSseDelta(line);
        if (delta != null) yield delta;
      }
    } on DioException catch (e) {
      throw _mapError(e);
    } on Exception {
      throw const NetworkFailure(
        'Koneksi ke layanan AI terputus. Coba lagi.',
      );
    }
  }

  Map<String, Object> _body(List<ChatMessage> messages) => {
        'model': AiConfig.model,
        'stream': true,
        'max_tokens': AiConfig.maxTokens,
        'temperature': AiConfig.temperature,
        'messages': [
          for (final m in messages) {'role': m.role.name, 'content': m.content},
        ],
      };

  Failure _mapError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return const UnauthorizedFailure(
        'API key tidak valid. Periksa kembali di pengaturan.',
      );
    }
    if (code == 429) {
      return const NetworkFailure(
        'Batas permintaan layanan AI tercapai. Coba lagi sebentar lagi.',
      );
    }
    if (code != null && code >= 500) {
      return const NetworkFailure('Layanan AI sedang bermasalah.');
    }
    return const NetworkFailure(
      'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet.',
    );
  }
}
