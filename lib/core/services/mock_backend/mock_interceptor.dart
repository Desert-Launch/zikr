import 'package:dio/dio.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/mock_backend/handlers/auth_handler.dart';
import 'package:quran/core/services/mock_backend/handlers/profile_handler.dart';
import 'package:quran/core/services/mock_backend/mock_database.dart';
import 'package:quran/core/services/mock_backend/models/m_mock_response.dart';
import 'package:quran/core/services/network/end_points.dart';

/// Dio interceptor that resolves requests against the in-app fake backend
/// when [AppConfig.useMockBackend] is true. Requests whose path isn't
/// registered here fall through to the real network.
class MockInterceptor extends Interceptor {
  MockInterceptor(this._db)
      : _auth = AuthHandler(_db),
        _profile = ProfileHandler(_db);

  final MockDatabase _db;
  final AuthHandler _auth;
  final ProfileHandler _profile;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!AppConfig.useMockBackend) return handler.next(options);

    await _db.hydrate();

    final MockResponse? response = switch (options.path) {
      EndPoints.authLogin => _auth.login(options.data),
      EndPoints.authRegister => _auth.register(options.data),
      EndPoints.authForgot => _auth.forgotPassword(options.data),
      EndPoints.authVerifyOtp => _auth.verifyOtp(options.data),
      EndPoints.authReset => _auth.resetPassword(options.data),
      EndPoints.authLogout => _auth.logout(options.headers),
      EndPoints.authMe => _auth.me(options.headers),
      EndPoints.authRefresh => _auth.refresh(options.data),
      EndPoints.usersProfile => _profile.handle(options),
      _ => null,
    };

    if (response == null) return handler.next(options);

    if (response.delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: response.delayMs));
    } else {
      // Realistic baseline latency.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    handler.resolve(Response(
      requestOptions: options,
      statusCode: response.statusCode,
      data: response.body,
      headers: Headers.fromMap({
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      }),
    ));
  }
}
