import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10/core/failures.dart';
import 'package:week10/infrastructure/network/failure_mapper.dart';

DioException _dio(DioExceptionType type, {int? statusCode}) => DioException(
      requestOptions: RequestOptions(path: '/pengumuman'),
      type: type,
      response: statusCode == null
          ? null
          : Response<void>(
              requestOptions: RequestOptions(path: '/pengumuman'),
              statusCode: statusCode,
            ),
    );

void main() {
  group('toFailure', () {
    test('Failure yang sudah ada diteruskan apa adanya', () {
      const original = ValidationFailure('Judul kosong');
      expect(toFailure(original), same(original));
    });

    test('timeout dianggap masalah jaringan, bukan error tak dikenal', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(toFailure(_dio(type)), isA<NetworkFailure>());
      }
    });

    test('koneksi gagal menjadi NetworkFailure', () {
      expect(
        toFailure(_dio(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });

    test('401 dan 403 menjadi UnauthorizedFailure', () {
      expect(
        toFailure(_dio(DioExceptionType.badResponse, statusCode: 401)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        toFailure(_dio(DioExceptionType.badResponse, statusCode: 403)),
        isA<UnauthorizedFailure>(),
      );
    });

    test('5xx menjadi NetworkFailure, 4xx lain menyebut kode status', () {
      expect(
        toFailure(_dio(DioExceptionType.badResponse, statusCode: 503)),
        isA<NetworkFailure>(),
      );
      expect(
        toFailure(_dio(DioExceptionType.badResponse, statusCode: 404)).message,
        contains('404'),
      );
    });

    test('permintaan dibatalkan menjadi NetworkFailure', () {
      expect(
        toFailure(_dio(DioExceptionType.cancel)),
        isA<NetworkFailure>(),
      );
    });

    test('error non-Dio menjadi UnknownFailure dengan pesan asli', () {
      final failure = toFailure(Exception('boom'));
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'boom');
    });
  });
}
