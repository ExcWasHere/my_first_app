import '../entities/push_registration.dart';
import '../repositories/device_repository.dart';
import '../repositories/push_repository.dart';

class SetupPushNotifications {
  const SetupPushNotifications({
    required PushRepository push,
    required DeviceRepository devices,
  })  : _push = push,
        _devices = devices;

  final PushRepository _push;
  final DeviceRepository _devices;

  Stream<PushRegistration> call() async* {
    final granted = await _push.requestPermission();
    if (!granted) return;

    var subscribed = false;
    await for (final token in _push.tokens()) {
      final failure = await _devices.registerToken(token);
      yield PushRegistration(token: token, failure: failure);
      if (!subscribed) {
        subscribed = true;
        await _push.subscribeToCampusTopic();
      }
    }
  }
}
