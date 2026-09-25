import '../errors/app_failure.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, String>? details;
  ApiException(this.code, this.message, [this.details]);

  /// Translate to the app's typed failure.
  AppFailure toFailure() {
    switch (code) {
      case 'VALIDATION_ERROR':
        return ValidationFailure(message);
      case 'UNAUTHORIZED':
      case 'INVALID_CREDENTIALS':
      case 'INVALID_TOKEN':
      case 'ACCOUNT_DISABLED':
        return AuthFailure(message);
      case 'FORBIDDEN':
        return PermissionFailure(message);
      case 'NOT_FOUND':
        return NotFoundFailure(message);
      case 'PHONE_TAKEN':
      case 'EMAIL_TAKEN':
        return ValidationFailure(message);
      case 'INTERNAL_ERROR':
      default:
        return UnknownFailure(message);
    }
  }
}