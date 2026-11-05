import '../../../../core/failures.dart';

abstract class DeviceRepository {
  Future<Failure?> registerToken(String token);
}
