class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backroom-voodoo.onrender.com',
  );

  // Android emulator: use 10.0.2.2 instead of localhost
  // static const String baseUrl = 'http://10.0.2.2:8080';

  // ⬇ bumped from 15 → 45 s for Render free-tier cold starts
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);

  static const String healthz = '/healthz';

  // Auth
  static const String register  = '/v1/auth/register';
  static const String login     = '/v1/auth/login';
  static const String refresh   = '/v1/auth/refresh';
  static const String logout    = '/v1/auth/logout';
  static const String logoutAll = '/v1/auth/logout-all';

  // Users
  static const String me             = '/v1/users/me';
  static const String changePassword = '/v1/users/me/change-password';
}