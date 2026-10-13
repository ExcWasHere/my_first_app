import 'package:flutter_test/flutter_test.dart';
import 'package:week6/core/failures.dart';
import 'package:week6/features/notifications/domain/repositories/device_repository.dart';
import 'package:week6/features/notifications/domain/repositories/push_repository.dart';
import 'package:week6/features/notifications/domain/usecases/setup_push_notifications.dart';

class FakePushRepository implements PushRepository {
  FakePushRepository({this.granted = true, this.tokenList = const []});
  final bool granted;
  final List<String> tokenList;
  int subscribeCalls = 0;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Stream<String> tokens() => Stream.fromIterable(tokenList);

  @override
  Future<void> subscribeToCampusTopic() async => subscribeCalls++;

  @override
  Future<void> unsubscribeFromCampusTopic() async {}

  @override
  Stream<String> get routes => const Stream.empty();

  @override
  Future<String?> takeLaunchRoute() async => null;
}

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository({this.failure});
  final Failure? failure;
  final registered = <String>[];

  @override
  Future<Failure?> registerToken(String token) async {
    registered.add(token);
    return failure;
  }
}

void main() {
  test('izin ditolak: tidak ada pendaftaran dan tidak subscribe', () async {
    final push = FakePushRepository(granted: false, tokenList: ['t1']);
    final devices = FakeDeviceRepository();
    final events =
        await SetupPushNotifications(push: push, devices: devices)().toList();
    expect(events, isEmpty);
    expect(devices.registered, isEmpty);
    expect(push.subscribeCalls, 0);
  });

  test('setiap token didaftarkan dan subscribe hanya sekali', () async {
    final push = FakePushRepository(tokenList: ['t1', 't2']);
    final devices = FakeDeviceRepository();
    final events =
        await SetupPushNotifications(push: push, devices: devices)().toList();
    expect(devices.registered, ['t1', 't2']);
    expect(events.map((e) => e.token), ['t1', 't2']);
    expect(events.every((e) => e.failure == null), isTrue);
    expect(push.subscribeCalls, 1);
  });

  test('gagal daftar token dilaporkan sebagai failure, alur tetap jalan',
      () async {
    final push = FakePushRepository(tokenList: ['t1']);
    final devices =
        FakeDeviceRepository(failure: const NetworkFailure('offline'));
    final events =
        await SetupPushNotifications(push: push, devices: devices)().toList();
    expect(events.single.failure, isA<NetworkFailure>());
    expect(push.subscribeCalls, 1);
  });
}
