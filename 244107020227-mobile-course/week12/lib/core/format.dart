import '../routes.dart';

String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  final route = raw is String ? raw.trim() : '';
  if (route.isEmpty) return AppRoutes.home;
  return route.startsWith('/') ? route : '/$route';
}

String maskToken(String? token, {int visible = 12}) {
  if (token == null) return 'belum ada';
  if (token.length < visible) return token;
  return '${token.substring(0, visible)}...';
}
