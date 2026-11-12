import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di.dart';
import '../../data/device_repository_impl.dart';
import '../../domain/entities/push_registration.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/push_repository.dart';
import '../../domain/usecases/setup_push_notifications.dart';

final pushRepositoryProvider = Provider<PushRepository>(
  (ref) => throw UnimplementedError(
      'pushRepositoryProvider harus di-override di ProviderScope (main.dart)'),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(ref.watch(dioProvider)),
);

final setupPushProvider = Provider<SetupPushNotifications>(
  (ref) => SetupPushNotifications(
    push: ref.watch(pushRepositoryProvider),
    devices: ref.watch(deviceRepositoryProvider),
  ),
);

final pushControllerProvider =
    NotifierProvider<PushController, String?>(PushController.new);

class PushController extends Notifier<String?> {
  StreamSubscription<PushRegistration>? _sub;

  @override
  String? build() {
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  Future<void> start() async {
    await _sub?.cancel();
    _sub = ref.read(setupPushProvider).call().listen(
      (event) {
        debugPrint('PUSH token diterima (${event.token.length} karakter)');
        state = event.token;
        final failure = event.failure;
        if (failure == null) {
          debugPrint('PUSH POST /devices berhasil');
        } else {
          debugPrint('PUSH POST /devices gagal: ${failure.message}');
        }
      },
      onError: (Object e, StackTrace st) =>
          debugPrint('PUSH setup error: $e\n$st'),
    );
  }
}
