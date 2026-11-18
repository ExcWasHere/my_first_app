import '../../../core/failures.dart';
import '../../../infrastructure/network/failure_mapper.dart';
import '../../../infrastructure/storage/token_store.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStore tokenStore,
  })  : _remote = remote,
        _tokenStore = tokenStore;

  final AuthRemoteDataSource _remote;
  final TokenStore _tokenStore;

  @override
  Future<bool> hasSession() async => (await _tokenStore.readAccess()) != null;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remote.login(email: email, password: password);
      await _tokenStore.save(access: session.access, refresh: session.refresh);
      return (session: session, failure: null);
    } catch (e) {
      return (session: null, failure: toFailure(e));
    }
  }

  @override
  Future<void> logout() => _tokenStore.clear();
}
