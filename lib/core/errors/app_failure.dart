/// Typed failures so UI can render meaningful messages and services can
/// throw something the controller can catch without depending on
/// framework-specific exception types.
sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
