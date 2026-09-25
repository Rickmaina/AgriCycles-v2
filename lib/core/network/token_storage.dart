import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess  = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';

  static Future<void> save({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccess,  value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  static Future<String?> accessToken()  => _storage.read(key: _kAccess);
  static Future<String?> refreshToken() => _storage.read(key: _kRefresh);

  static Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}