## Project Description

This week the **Campus Notification App** from Week 6 (Riverpod + GoRouter + Dio + flutter_secure_storage + Firebase Cloud Messaging) was **refactored into a feature-first Clean Architecture**.

The code is split into three layers per feature, and dependencies only point inwards:

```
presentation (widgets, notifiers, router)
      |
      v  depends on
domain (entities, repository interfaces, use cases, failures)
      ^
      |  implemented by
data (repository implementations, Dio, secure storage, FCM)
```

Highlights:

- **Auth**: `Login` use case holds the business rule (email must contain `@`, password at least 6 characters). `AuthRepositoryImpl` talks to `AuthRemoteDataSource` (still a mock, with the Firebase Auth swap point kept) and saves tokens through `TokenStore`. `AuthNotifier` only calls the use case and the repository interface.
- **Announcements**: `Announcement` entity, `AnnouncementRepository` interface, in-memory implementation (the list used to be hardcoded in `HomePage`), `GetAnnouncements` use case.
- **Notifications**: `PushRepository` (permission, tokens, topic, notification routes) and `DeviceRepository` (`POST /devices`) are interfaces in `domain`. `FcmPushRepository` and `DeviceRepositoryImpl` implement them in `data`. `SetupPushNotifications` combines both repositories into one flow: permission, register every token, subscribe to the topic once.
- **Errors**: raw exceptions are converted to a `Failure` at the data boundary (`failure_mapper.dart`); the UI only receives `message`.
- **Pure functions**: `routeFromMessage` and `maskToken` live in `lib/core/format.dart` so they can be tested without widgets.
- **Removed global state**: `fcmTokenNotifier` and `pendingDeepLink` no longer exist; the token is Riverpod state (`pushControllerProvider`) and the pending deep link is handled inside `FcmPushRepository`.