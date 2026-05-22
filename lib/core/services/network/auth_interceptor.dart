import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/auth/data/sources/local/box_auth_token.dart';

/// Stamps `Authorization: Bearer <token>` onto every outgoing request when
/// a token is present in [BoxAuthToken]. Skips paths under `/auth/` (so we
/// never send a stale token to login/register/refresh).
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.startsWith('/auth/') && options.path != '/auth/me' &&
        options.path != '/auth/logout') {
      return handler.next(options);
    }
    try {
      final box = Modular.get<BoxAuthToken>();
      final token = box.current();
      if (token != null && token.accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${token.accessToken}';
      }
    } catch (_) {
      // Box not registered yet (boot ordering) — skip silently.
    }
    handler.next(options);
  }
}
