import 'package:dio/dio.dart';
import 'package:quran/core/services/network/base_dio.dart';
import 'package:quran/core/services/network/end_points.dart';

/// Thin wrapper over [BaseDio] for /auth/* endpoints. The mock interceptor
/// short-circuits these in dev; in prod they'd hit a real backend.
class DSRemoteAuth {
  DSRemoteAuth(this._dio);
  final BaseDio _dio;

  Future<Response<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) {
    return _dio.dio.post<Map<String, dynamic>>(
      EndPoints.authLogin,
      data: {'identifier': identifier, 'password': password},
    );
  }

  Future<Response<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _dio.dio.post<Map<String, dynamic>>(
      EndPoints.authRegister,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  Future<Response<Map<String, dynamic>>> forgotPassword(String email) {
    return _dio.dio.post<Map<String, dynamic>>(
      EndPoints.authForgot,
      data: {'email': email},
    );
  }

  Future<Response<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _dio.dio.post<Map<String, dynamic>>(
      EndPoints.authVerifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<Response<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _dio.dio.post<Map<String, dynamic>>(
      EndPoints.authReset,
      data: {'email': email, 'otp': otp, 'new_password': newPassword},
    );
  }

  Future<Response<dynamic>> logout() {
    return _dio.dio.post<dynamic>(EndPoints.authLogout);
  }

  Future<Response<Map<String, dynamic>>> me() {
    return _dio.dio.get<Map<String, dynamic>>(EndPoints.authMe);
  }
}
