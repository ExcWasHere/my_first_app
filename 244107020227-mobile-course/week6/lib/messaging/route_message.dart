import '../routes.dart';

String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  final route = raw is String ? raw.trim() : '';
  if (route.isEmpty) return AppRoutes.home;
  return route.startsWith('/') ? route : '/$route';
}