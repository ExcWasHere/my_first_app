import 'package:dio/dio.dart';
import '../../core/failures.dart';

Failure toFailure(Object error) {
  if (error is Failure) return error;
  if (error is DioException) return _fromDio(error);
  return UnknownFailure(messageOf(error));
}

Failure _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure('Koneksi lambat. Coba lagi sebentar lagi.');
    case DioExceptionType.connectionError:
      return const NetworkFailure('Tidak ada koneksi internet.');
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) {
        return const UnauthorizedFailure('Sesi berakhir. Silakan login lagi.');
      }
      if (code == 403) {
        return const UnauthorizedFailure(
            'Kamu tidak punya akses ke halaman ini.');
      }
      if (code != null && code >= 500) {
        return const NetworkFailure(
            'Server sedang bermasalah. Coba lagi nanti.');
      }
      return NetworkFailure('Permintaan gagal (kode $code).');
    case DioExceptionType.cancel:
      return const NetworkFailure('Permintaan dibatalkan.');
    default:
      return const UnknownFailure('Terjadi kesalahan tak terduga.');
  }
}
