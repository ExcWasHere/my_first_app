sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

/// Pesan ramah pengguna dari error apa pun yang sampai ke UI.
String messageOf(Object error) {
  if (error is Failure) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
