import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/infrastructure/network/api_client.dart';
import 'package:week10/infrastructure/network/failure_mapper.dart';
import 'package:week10/infrastructure/storage/token_store.dart';

/// Server palsu: hanya menerima token yang dianggap masih berlaku.
class _FakeAdapter implements HttpClientAdapter {
  static const validToken = 'token-baru';

  final requestedTokens = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    requestedTokens.add(auth);
    if (auth == 'Bearer $validToken') {
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'error': 'token kedaluwarsa'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _client(_FakeAdapter adapter, {RefreshAccessToken? refresh}) {
  final dio = buildApiClient(
    store: TokenStore(),
    refreshAccessToken: refresh ?? (_) async => 'token-baru',
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'token-lama',
      'refresh_token': 'refresh-1',
    });
  });

  test('401 memicu refresh lalu mengulang permintaan dengan token baru',
      () async {
    final adapter = _FakeAdapter();
    final refreshes = <String>[];

    final response = await _client(adapter, refresh: (refreshToken) async {
      refreshes.add(refreshToken);
      return 'token-baru';
    }).get<Map<String, dynamic>>('/pengumuman');

    expect(response.statusCode, 200);
    expect(refreshes, ['refresh-1']);
    expect(adapter.requestedTokens, [
      'Bearer token-lama',
      'Bearer token-baru',
    ]);
    expect(await TokenStore().readAccess(), 'token-baru');
    expect(await TokenStore().readRefresh(), 'refresh-1');
  });

  test('refresh gagal: token dibersihkan dan error 401 diteruskan', () async {
    final adapter = _FakeAdapter();

    final error = await _client(
      adapter,
      refresh: (_) async => throw Exception('refresh ditolak'),
    ).get<Map<String, dynamic>>('/pengumuman').then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );

    expect(error, isA<DioException>());
    expect(toFailure(error!), isA<UnauthorizedFailure>());
    expect(await TokenStore().readAccess(), isNull);
    expect(await TokenStore().readRefresh(), isNull);
  });

  test('tanpa refresh token, permintaan tidak diulang', () async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'token-lama'});
    final adapter = _FakeAdapter();
    var refreshes = 0;

    final error = await _client(adapter, refresh: (_) async {
      refreshes++;
      return 'token-baru';
    }).get<Map<String, dynamic>>('/pengumuman').then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );

    expect(error, isA<DioException>());
    expect(refreshes, 0);
    expect(adapter.requestedTokens, ['Bearer token-lama']);
  });
}
