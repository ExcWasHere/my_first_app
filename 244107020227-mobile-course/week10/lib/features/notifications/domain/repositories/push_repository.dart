abstract class PushRepository {
  Future<bool> requestPermission();
  Stream<String> tokens();

  Future<void> subscribeToCampusTopic();
  Future<void> unsubscribeFromCampusTopic();
  Stream<String> get routes;
  Future<String?> takeLaunchRoute();
}
