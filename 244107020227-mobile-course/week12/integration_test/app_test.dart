import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/features/announcements/domain/entities/announcement.dart';
import 'package:week10/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:week10/features/announcements/presentation/providers/announcements_providers.dart';
import 'package:week10/features/auth/domain/entities/auth_session.dart';
import 'package:week10/features/auth/domain/repositories/auth_repository.dart';
import 'package:week10/features/auth/presentation/providers/auth_providers.dart';
import 'package:week10/features/notifications/domain/repositories/push_repository.dart';
import 'package:week10/features/notifications/presentation/providers/push_providers.dart';
import 'package:week10/main.dart';

/// Auth palsu: satu-satunya state yang disimpan adalah status login.
class _FakeAuthRepository implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<bool> hasSession() async => _loggedIn;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@') || password.length < 6) {
      return (
        session: null,
        failure: const ValidationFailure('Email atau kata sandi tidak valid'),
      );
    }
    _loggedIn = true;
    return (
      session: AuthSession(access: 'access-$email', refresh: 'refresh-$email'),
      failure: null,
    );
  }

  @override
  Future<void> logout() async => _loggedIn = false;
}

class _FakeAnnouncementRepository implements AnnouncementRepository {
  static const _items = [
    Announcement(id: '1', title: 'Jadwal UTS Genap', body: 'UTS mulai Senin.'),
    Announcement(
        id: '2', title: 'Beasiswa Prestasi', body: 'Daftar sebelum 30 Juni.'),
  ];

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async => (items: _items, failure: null);

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncement(
      String id) async {
    for (final a in _items) {
      if (a.id == id) return (item: a, failure: null);
    }
    return (
      item: null,
      failure: const NetworkFailure('Pengumuman tidak ditemukan.'),
    );
  }
}

/// Push palsu: tanpa Firebase, token tidak pernah dikirim.
class _FakePushRepository implements PushRepository {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<String> tokens() => const Stream.empty();

  @override
  Future<void> subscribeToCampusTopic() async {}

  @override
  Future<void> unsubscribeFromCampusTopic() async {}

  @override
  Stream<String> get routes => const Stream.empty();

  @override
  Future<String?> takeLaunchRoute() async => null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login -> cari pengumuman -> buka detail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          announcementRepositoryProvider
              .overrideWithValue(_FakeAnnouncementRepository()),
          pushRepositoryProvider.overrideWithValue(_FakePushRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Belum punya sesi: router mengarahkan ke halaman login.
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'mhs@polinema.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'rahasia1',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    // Sudah login: beranda menampilkan daftar pengumuman.
    expect(find.text('Campus Notify'), findsOneWidget);
    expect(find.text('Jadwal UTS Genap'), findsOneWidget);
    expect(find.text('Beasiswa Prestasi'), findsOneWidget);

    // Pencarian menyaring daftar.
    await tester.enterText(
      find.byKey(const Key('announcement-search-field')),
      'beasiswa',
    );
    await tester.pumpAndSettle();
    expect(find.text('Beasiswa Prestasi'), findsOneWidget);
    expect(find.text('Jadwal UTS Genap'), findsNothing);

    // Membuka detail menampilkan isi pengumuman.
    await tester.tap(find.text('Beasiswa Prestasi'));
    await tester.pumpAndSettle();
    expect(find.text('Pengumuman 2'), findsOneWidget);
    expect(find.text('Daftar sebelum 30 Juni.'), findsOneWidget);
  });
}
