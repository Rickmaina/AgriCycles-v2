/// API configuration.
///
/// Two environment-driven settings:
///
/// 1. `USE_MOCK` — when true, the auth service uses in-memory seed
///    data instead of HTTP. Useful for frontend testing before the
///    backend is CORS-ready.
///    Run: `flutter run -d chrome --dart-define=USE_MOCK=true`
///
/// 2. `API_BASE_URL` — override the backend host without code changes.
///    Run: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
class ApiConfig {
  ApiConfig._();

  /// Toggle in-memory mock data.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  /// Backend base URL. Overridable at build time.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backroom-voodoo.onrender.com',
  );

  // Android emulator alternative: http://10.0.2.2:8080

  /// Bumped for Render free-tier cold starts.
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);

  static const String healthz = '/healthz';

  // ── Auth ────────────────────────────────────────────────────
  static const String register = '/v1/auth/register';
  static const String login = '/v1/auth/login';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String logoutAll = '/v1/auth/logout-all';

  // ── Users ───────────────────────────────────────────────────
  static const String me = '/v1/users/me';
  static const String changePassword = '/v1/users/me/change-password';
}
