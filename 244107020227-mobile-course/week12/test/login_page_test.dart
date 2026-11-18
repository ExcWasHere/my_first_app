import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/auth/domain/entities/auth_session.dart';
import 'package:week10/features/auth/domain/repositories/auth_repository.dart';
import 'package:week10/features/auth/presentation/pages/login_page.dart';
import 'package:week10/features/auth/presentation/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

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
      session: AuthSession(access: 'access-$email', refresh: 'refresh'),
      failure: null,
    );
  }

  @override
  Future<void> logout() async {}
}

Future<_FakeAuthRepository> _pump(
  WidgetTester tester, {
  Failure? failure,
}) async {
  final auth = _FakeAuthRepository(failure: failure);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _submit(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(find.byKey(const Key('login-email-field')), email);
  await tester.enterText(
    find.byKey(const Key('login-password-field')),
    password,
  );
  await tester.tap(find.byKey(const Key('login-submit-button')));
  await tester.pumpAndSettle();
}

void main() {
  group('LoginPage', () {
    testWidgets('input tidak valid menampilkan pesan tanpa memanggil repository',
        (tester) async {
      final auth = await _pump(tester);

      await _submit(tester, email: 'bukan-email', password: '123');

      expect(find.text('Email atau kata sandi tidak valid'), findsOneWidget);
      expect(auth.loginCalls, 0);
    });

    testWidgets('kredensial valid tidak menampilkan error', (tester) async {
      final auth = await _pump(tester);

      await _submit(
        tester,
        email: 'mhs@polinema.ac.id',
        password: 'rahasia1',
      );

      expect(find.text('Email atau kata sandi tidak valid'), findsNothing);
      expect(auth.loginCalls, 1);
    });

    testWidgets('error jaringan dari repository ditampilkan', (tester) async {
      final auth = await _pump(
        tester,
        failure: const NetworkFailure('Tidak ada koneksi internet.'),
      );

      await _submit(
        tester,
        email: 'mhs@polinema.ac.id',
        password: 'rahasia1',
      );

      expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);
      expect(auth.loginCalls, 1);
    });
  });
}
