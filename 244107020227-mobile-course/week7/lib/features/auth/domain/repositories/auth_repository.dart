import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<bool> hasSession();
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}
