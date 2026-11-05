import '../../../../core/failures.dart';

class PushRegistration {
  const PushRegistration({required this.token, this.failure});
  final String token;
  final Failure? failure;
}
