import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repo.dart';
import 'token_store.dart';

final dioProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://example-campus-api.test',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      final alreadyRetried = e.requestOptions.extra['retried'] == true;
      if (e.response?.statusCode == 401 && !alreadyRetried) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final opts = e.requestOptions
            ..headers['Authorization'] = 'Bearer $renewed'
            ..extra['retried'] = true;
          return handler.resolve(await dio.fetch(opts));
        } catch (_) {
          await store.clear();
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}