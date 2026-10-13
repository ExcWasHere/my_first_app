import 'package:flutter_test/flutter_test.dart';
import 'package:week6/core/failures.dart';
import 'package:week6/features/auth/domain/entities/auth_session.dart';
import 'package:week6/features/auth/domain/repositories/auth_repository.dart';
import 'package:week6/features/auth/domain/usecases/login.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failure});
  final Failure? failure;
  int loginCalls = 0;

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (failure != null) return (session: null, failure: failure);
    return (
      session: AuthSession(access: 'a-$email', refresh: 'r-$email'),
      failure: null,
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  test('Login sukses meneruskan sesi dari repository', () async {
    final repo = FakeAuthRepository();
    final result = await Login(repo)
        .call(email: 'mhs@polinema.ac.id', password: 'rahasia1');
    expect(result.failure, isNull);
    expect(result.session?.access, 'a-mhs@polinema.ac.id');
    expect(repo.loginCalls, 1);
  });

  test('Email tanpa @ ditolak tanpa memanggil repository', () async {
    final repo = FakeAuthRepository();
    final result = await Login(repo).call(email: 'mhs', password: 'rahasia1');
    expect(result.failure, isA<ValidationFailure>());
    expect(result.session, isNull);
    expect(repo.loginCalls, 0);
  });

  test('Kata sandi < 6 karakter ditolak', () async {
    final repo = FakeAuthRepository();
    final result = await Login(repo).call(email: 'a@b.c', password: '12345');
    expect(result.failure, isA<ValidationFailure>());
    expect(repo.loginCalls, 0);
  });

  test('Failure dari repository diteruskan tanpa melempar', () async {
    final repo = FakeAuthRepository(
        failure: const NetworkFailure('Tidak ada koneksi internet.'));
    final result =
        await Login(repo).call(email: 'a@b.c', password: 'rahasia1');
    expect(result.failure, isA<NetworkFailure>());
    expect(result.session, isNull);
  });
}
