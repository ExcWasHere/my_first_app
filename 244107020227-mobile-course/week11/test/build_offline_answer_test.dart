import 'package:flutter_test/flutter_test.dart';
import 'package:week10/features/announcements/domain/entities/announcement.dart';
import 'package:week10/features/chat/domain/usecases/build_offline_answer.dart';

void main() {
  const build = BuildOfflineAnswer();

  test('menampilkan maksimal 3 judul terbaru', () {
    final items = [
      for (var i = 1; i <= 5; i++)
        Announcement(id: '$i', title: 'Judul $i', body: 'Isi $i'),
    ];
    final answer = build(items);
    expect(answer, contains('Judul 3'));
    expect(answer, isNot(contains('Judul 4')));
  });

  test('data kosong tetap memberi pesan yang jelas', () {
    expect(build(const []), contains('belum ada data'));
  });
}
