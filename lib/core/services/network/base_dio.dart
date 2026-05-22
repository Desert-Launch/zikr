import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/mock_backend/mock_interceptor.dart';
import 'package:quran/core/services/network/auth_interceptor.dart';

/// Thin Dio wrapper used by every data source that talks to the backend.
///
/// Order of interceptors matters: the auth interceptor stamps the
/// `Authorization` header first; the mock interceptor (when enabled)
/// short-circuits matching routes; anything past it hits the real network.
class BaseDio {
  BaseDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(AuthInterceptor());
    if (AppConfig.useMockBackend) {
      _dio.interceptors.add(Modular.get<MockInterceptor>());
    }
  }

  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);
}
