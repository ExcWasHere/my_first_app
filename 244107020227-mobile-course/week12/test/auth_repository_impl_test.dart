import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/auth/data/auth_remote_data_source.dart';
import 'package:week10/features/auth/data/auth_repository_impl.dart';
import 'package:week10/features/auth/domain/entities/auth_session.dart';
import 'package:week10/infrastructure/storage/token_store.dart';

class _FakeRemote extends AuthRemoteDataSource {
  _FakeRemote({this.error});

  final Exception? error;
  int loginCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (error != null) throw error!;
    return AuthSession(access: 'access-$email', refresh: 'refresh-$email');
  }
}

AuthRepositoryImpl _build(_FakeRemote remote) =>
    AuthRepositoryImpl(remote: remote, tokenStore: TokenStore());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('login sukses menyimpan token sehingga sesi dikenali', () async {
    final remote = _FakeRemote();
    final repo = _build(remote);

    expect(await repo.hasSession(), isFalse);
    final result =
        await repo.login(email: 'mhs@polinema.ac.id', password: 'rahasia1');

    expect(result.failure, isNull);
    expect(result.session?.access, 'access-mhs@polinema.ac.id');
    expect(await repo.hasSession(), isTrue);
  });

  test('login gagal memetakan error dan tidak menyimpan token', () async {
    final repo = _build(_FakeRemote(error: Exception('server mati')));

    final result = await repo.login(email: 'a@b.c', password: 'rahasia1');

    expect(result.session, isNull);
    expect(result.failure, isA<UnknownFailure>());
    expect(result.failure?.message, 'server mati');
    expect(await repo.hasSession(), isFalse);
  });

  test('logout menghapus token', () async {
    final repo = _build(_FakeRemote());
    await repo.login(email: 'a@b.c', password: 'rahasia1');

    await repo.logout();

    expect(await repo.hasSession(), isFalse);
  });
}
