import 'package:flutter_test/flutter_test.dart';
import 'package:week9/features/announcements/domain/entities/announcement.dart';
import 'package:week9/features/announcements/domain/usecases/search_announcements.dart';

const _items = [
  Announcement(id: '1', title: 'Jadwal UTS Genap', body: 'Ruang berubah'),
  Announcement(id: '2', title: 'Beasiswa Prestasi', body: 'Pendaftaran dibuka'),
  Announcement(id: '3', title: 'jadwal praktikum', body: 'Lab 3'),
];

void main() {
  const search = SearchAnnouncements();

  test('filter abaikan huruf besar/kecil', () {
    expect(search(_items, 'JADWAL'), hasLength(2));
    expect(search(_items, 'jadwal'), hasLength(2));
  });

  test('query tak cocok kembalikan kosong', () {
    expect(search(_items, 'zzz-tak-ada'), isEmpty);
  });

  test('query kosong atau hanya spasi kembalikan semua', () {
    expect(search(_items, ''), hasLength(3));
    expect(search(_items, '   '), hasLength(3));
  });

  test('spasi di awal/akhir query diabaikan', () {
    final result = search(_items, '  beasiswa ');
    expect(result.single.id, '2');
  });

  test('hanya mencari di judul, bukan isi pengumuman', () {
    expect(search(_items, 'pendaftaran'), isEmpty);
  });
}
