import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  AuthInterceptor(this.dio);

  bool _refreshing = false;

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Skip auth on unauthenticated endpoints
    final skip = {
      ApiConfig.register,
      ApiConfig.login,
      ApiConfig.refresh,
      ApiConfig.healthz,
    }.contains(options.path);

    if (!skip) {
      final token = await TokenStorage.accessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final response = err.response;
    final is401 = response?.statusCode == 401;

    if (!is401 || _refreshing) {
      return handler.next(err);
    }

    // Only retry once
    final opts = err.requestOptions;
    if (opts.extra['retried'] == true) return handler.next(err);

    _refreshing = true;
    try {
      final rt = await TokenStorage.refreshToken();
      if (rt == null) {
        await TokenStorage.clear();
        return handler.next(err);
      }

      final res = await dio.post(
        ApiConfig.refresh,
        data: {'refresh_token': rt},
      );
      final tokens = res.data['data']['tokens'];
      await TokenStorage.save(
        access:  tokens['access_token'],
        refresh: tokens['refresh_token'],
      );

      // Retry original request once
      opts.extra['retried'] = true;
      opts.headers['Authorization'] = 'Bearer ${tokens['access_token']}';
      final retried = await dio.fetch(opts);
      return handler.resolve(retried);
    } catch (_) {
      await TokenStorage.clear();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}