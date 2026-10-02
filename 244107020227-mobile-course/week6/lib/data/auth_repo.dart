import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

class AuthSession {
  const AuthSession({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

class AuthRepository {
  // GANTI titik ini dengan FirebaseAuth.instance.signInWithEmailAndPassword
  // atau GoogleSignIn saat backend Firebase sudah siap.
  Future<AuthSession> login(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT: header.payload.signature (jangan parse manual di produksi,
    // gunakan verifikasi server).
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw Exception('Refresh token hilang');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}