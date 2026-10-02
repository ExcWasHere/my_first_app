import 'package:dio/dio.dart';

String messageFromDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Koneksi lambat. Coba lagi sebentar lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) return 'Sesi berakhir. Silakan login lagi.';
      if (code == 403) return 'Kamu tidak punya akses ke halaman ini.';
      if (code != null && code >= 500) {
        return 'Server sedang bermasalah. Coba lagi nanti.';
      }
      return 'Permintaan gagal (kode $code).';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    default:
      return 'Terjadi kesalahan tak terduga.';
  }
}

String friendlyError(Object error) {
  if (error is DioException) return messageFromDioException(error);
  return error.toString().replaceFirst('Exception: ', '');
}