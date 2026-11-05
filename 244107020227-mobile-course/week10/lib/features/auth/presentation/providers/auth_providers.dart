import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final loginProvider =
    Provider<Login>((ref) => Login(ref.watch(authRepositoryProvider)));

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(authRepositoryProvider).hasSession();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginProvider)
        .call(email: email, password: password);
    final failure = result.failure;
    if (failure == null) {
      state = const AsyncData(true);
    } else {
      state = AsyncError(failure, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidateSelf();
  }
}
