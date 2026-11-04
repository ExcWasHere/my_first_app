import '../entities/announcement.dart';

/// Aturan bisnis pencarian pengumuman berdasarkan judul.
///
/// Murni Dart: tidak mengimpor Flutter, Dio, maupun Riverpod, sehingga bisa
/// diuji tanpa widget.
class SearchAnnouncements {
  const SearchAnnouncements();

  /// Mengembalikan pengumuman yang judulnya memuat [query].
  ///
  /// - Huruf besar/kecil diabaikan.
  /// - Spasi di awal/akhir [query] diabaikan.
  /// - [query] kosong mengembalikan seluruh [items].
  List<Announcement> call(List<Announcement> items, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return items;
    return items
        .where((a) => a.title.toLowerCase().contains(needle))
        .toList(growable: false);
  }
}
