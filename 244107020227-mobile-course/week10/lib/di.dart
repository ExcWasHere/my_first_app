import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/data/auth_remote_data_source.dart';
import 'infrastructure/network/api_client.dart';
import 'infrastructure/storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) => AuthRemoteDataSource());

final dioProvider = Provider<Dio>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return buildApiClient(
    store: ref.watch(tokenStoreProvider),
    refreshAccessToken: remote.refresh,
  );
});
