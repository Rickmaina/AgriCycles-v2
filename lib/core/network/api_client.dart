import 'dart:convert';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _build();

  Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
      // Don't throw on 4xx — we parse the envelope ourselves
      validateStatus: (_) => true,
    ));

    // 1. Auth — attaches/refreshes bearer token
    dio.interceptors.add(AuthInterceptor(dio));

    // 2. Debug logging (remove before shipping)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // ignore: avoid_print
        print('→ ${options.method} ${options.uri}');
        // ignore: avoid_print
        print('  headers: ${options.headers}');
        // ignore: avoid_print
        print('  body: ${options.data}');
        handler.next(options);
      },
      onResponse: (res, handler) {
        // ignore: avoid_print
        print('← ${res.statusCode} from ${res.requestOptions.path}');
        // ignore: avoid_print
        print('  raw: ${res.data}');
        handler.next(res);
      },
      onError: (err, handler) {
        // ignore: avoid_print
        print('✗ DIO ERROR ${err.type} ${err.message}');
        // ignore: avoid_print
        print('  uri: ${err.requestOptions.uri}');
        // ignore: avoid_print
        print('  sent headers: ${err.requestOptions.headers}');
        // ignore: avoid_print
        print('  sent body: ${err.requestOptions.data}');
        // ignore: avoid_print
        print('  response: ${err.response?.statusCode} ${err.response?.data}');
        handler.next(err);
      },
    ));

    return dio;
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    return _run(() => _dio.get(path, queryParameters: query));
  }

  Future<T> post<T>(String path, {Object? data}) async {
    return _run(() => _dio.post(path, data: data));
  }

  Future<T> patch<T>(String path, {Object? data}) async {
    return _run(() => _dio.patch(path, data: data));
  }

  Future<T> delete<T>(String path, {Object? data}) async {
    return _run(() => _dio.delete(path, data: data));
  }

  Future<T> _run<T>(Future<Response> Function() call) async {
    try {
      final res = await call();

      if (res.statusCode == 204) {
        return null as T;
      }

      dynamic body = res.data;

      // Handle empty body (usually a 500 with no content)
      if (body == null || (body is String && body.trim().isEmpty)) {
        throw UnknownFailure(
          'Server returned ${res.statusCode} with empty body '
              'from ${res.requestOptions.path}',
        );
      }

      // Decode if Dio didn't already
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw UnknownFailure(
            'Non-JSON response (status ${res.statusCode}): '
                '${body.length > 200 ? "${body.substring(0, 200)}…" : body}',
          );
        }
      }

      if (body is! Map) {
        throw const UnknownFailure('Unexpected response shape');
      }

      // Success envelope: { "data": ... }
      if (body.containsKey('data')) {
        return body['data'] as T;
      }

      // Error envelope: { "error": {...} }
      if (body.containsKey('error')) {
        final err = body['error'] as Map;
        throw ApiException(
          err['code']?.toString() ?? 'INTERNAL_ERROR',
          err['message']?.toString() ?? 'Something went wrong',
          (err['details'] as Map?)?.cast<String, String>(),
        ).toFailure();
      }

      throw const UnknownFailure('Response missing data/error envelope');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw (e.error as ApiException).toFailure();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
        //
      }
      throw  UnknownFailure('Network error: ${e.type} ${e.message}');
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      // ignore: avoid_print
      print('ApiClient unexpected: $e\n$st');
      throw const UnknownFailure();
    }
  }
}