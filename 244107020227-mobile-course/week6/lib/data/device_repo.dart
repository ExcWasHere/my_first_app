import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(dioProvider)),
);

class DeviceRepository {
  DeviceRepository(this._dio);
  final Dio _dio;

  Future<void> registerToken(String token) async {
    await _dio.post('/devices', data: {
      'fcm_token': token,
      'platform': 'android',
    });
  }
}