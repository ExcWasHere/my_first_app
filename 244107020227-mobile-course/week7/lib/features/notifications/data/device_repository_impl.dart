import 'package:dio/dio.dart';
import '../../../core/failures.dart';
import '../../../infrastructure/network/failure_mapper.dart';
import '../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Failure?> registerToken(String token) async {
    try {
      await _dio.post('/devices', data: {
        'fcm_token': token,
        'platform': 'android',
      });
      return null;
    } catch (e) {
      return toFailure(e);
    }
  }
}
