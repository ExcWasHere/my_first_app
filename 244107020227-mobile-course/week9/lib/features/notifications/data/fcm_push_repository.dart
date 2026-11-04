import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/format.dart';
import '../domain/repositories/push_repository.dart';

const _topic = 'pengumuman-kampus';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('BG message: ${message.messageId}');
}

class FcmPushRepository implements PushRepository {
  FcmPushRepository({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
  })  : _fcm = messaging ?? FirebaseMessaging.instance,
        _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _local;
  final _routes = StreamController<String>.broadcast();
  String? _pendingRoute;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initLocalNotifications();
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _emit(routeFromMessage(m.data)));
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _emit(routeFromMessage({'route': payload}));
      },
    );
  }

  void _emit(String route) {
    if (_routes.hasListener) {
      _routes.add(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<String> tokens() async* {
    final token = await _fcm.getToken();
    if (token != null) yield token;
    yield* _fcm.onTokenRefresh;
  }

  @override
  Future<void> subscribeToCampusTopic() => _fcm.subscribeToTopic(_topic);

  @override
  Future<void> unsubscribeFromCampusTopic() =>
      _fcm.unsubscribeFromTopic(_topic);

  @override
  Stream<String> get routes => _routes.stream;

  @override
  Future<String?> takeLaunchRoute() async {
    final initial = await _fcm.getInitialMessage();
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null) return pending;
    return initial == null ? null : routeFromMessage(initial.data);
  }
}
