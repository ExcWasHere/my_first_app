import 'package:flutter_test/flutter_test.dart';
import 'package:week6/core/format.dart';

void main() {
  group('routeFromMessage', () {
    test('tanpa route -> home', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': '   '}), '/');
    });
    test('menambahkan / di depan bila belum ada', () {
      expect(routeFromMessage({'route': ' pengumuman/2 '}), '/pengumuman/2');
    });
    test('route yang sudah diawali / dibiarkan', () {
      expect(routeFromMessage({'route': '/pengumuman/2'}), '/pengumuman/2');
    });
  });

  group('maskToken', () {
    test('null -> belum ada', () => expect(maskToken(null), 'belum ada'));
    test('token panjang dipotong 12 karakter', () {
      expect(maskToken('abcdefghijklmnop'), 'abcdefghijkl...');
    });
    test('token pendek tidak error', () => expect(maskToken('abc'), 'abc'));
  });
}
