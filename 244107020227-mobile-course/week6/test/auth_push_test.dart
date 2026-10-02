import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6/data/api_errors.dart';
import 'package:week6/data/auth_repo.dart';
import 'package:week6/data/token_store.dart';
import 'package:week6/messaging/route_message.dart';
import 'package:week6/providers/auth_provider.dart';

class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  bool failLogin = false;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (failLogin) throw Exception('Email atau kata sandi tidak valid');
    return const AuthSession(access: 'acc', refresh: 'ref');
  }

  @override
  Future<String> refresh(String refreshToken) async => 'acc-baru';
}

ProviderContainer makeContainer(FakeTokenStore store, FakeAuthRepository repo) {
  final container = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  return container;
}

DioException dioError(DioExceptionType type, {int? status}) {
  final ro = RequestOptions(path: '/x');
  return DioException(
    requestOptions: ro,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: ro, statusCode: status),
  );
}

void main() {
  group('routeFromMessage', () {
    test('kosong atau tanpa key -> home', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': '  '}), '/');
    });

    test('menambah slash di depan bila belum ada', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('route valid dipertahankan', () {
      expect(routeFromMessage({'route': '/pengumuman/3', 'id': '3'}),
          '/pengumuman/3');
    });

    test('tipe data bukan String -> home', () {
      expect(routeFromMessage({'route': 123}), '/');
    });
  });

  group('friendlyError', () {
    test('401 -> pesan sesi berakhir', () {
      final e = dioError(DioExceptionType.badResponse, status: 401);
      expect(friendlyError(e), contains('Sesi berakhir'));
    });

    test('timeout dan offline -> pesan ramah', () {
      expect(friendlyError(dioError(DioExceptionType.connectionTimeout)),
          contains('lambat'));
      expect(friendlyError(dioError(DioExceptionType.connectionError)),
          contains('internet'));
    });

    test('Exception biasa -> prefix dibuang', () {
      expect(friendlyError(Exception('Password salah')), 'Password salah');
    });
  });

  group('AuthNotifier', () {
    test('tanpa token -> belum login', () async {
      final c = makeContainer(FakeTokenStore(), FakeAuthRepository());
      expect(await c.read(authStateProvider.future), isFalse);
    });

    test('ada token -> sudah login', () async {
      final store = FakeTokenStore()..access = 'acc';
      final c = makeContainer(store, FakeAuthRepository());
      expect(await c.read(authStateProvider.future), isTrue);
    });

    test('login sukses menyimpan token', () async {
      final store = FakeTokenStore();
      final c = makeContainer(store, FakeAuthRepository());
      await c.read(authStateProvider.future);

      await c.read(authStateProvider.notifier).login('a@b.com', '123456');

      expect(c.read(authStateProvider).value, isTrue);
      expect(store.access, 'acc');
      expect(store.refresh, 'ref');
    });

    test('login gagal -> error dan token tidak tersimpan', () async {
      final store = FakeTokenStore();
      final repo = FakeAuthRepository()..failLogin = true;
      final c = makeContainer(store, repo);
      await c.read(authStateProvider.future);

      await c.read(authStateProvider.notifier).login('a@b.com', '123456');

      expect(c.read(authStateProvider).hasError, isTrue);
      expect(store.access, isNull);
    });

    test('logout membersihkan sesi (paksa login ulang)', () async {
      final store = FakeTokenStore()
        ..access = 'acc'
        ..refresh = 'ref';
      final c = makeContainer(store, FakeAuthRepository());
      await c.read(authStateProvider.future);

      await c.read(authStateProvider.notifier).logout();

      expect(store.access, isNull);
      expect(store.refresh, isNull);
      expect(await c.read(authStateProvider.future), isFalse);
    });
  });
}