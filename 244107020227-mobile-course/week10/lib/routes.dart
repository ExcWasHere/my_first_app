abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcementPattern = '/pengumuman/:id';
  static const chat = '/chat';
  static String announcement(String id) => '/pengumuman/$id';
}
