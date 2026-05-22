/// Single source of truth for backend paths.
///
/// Keep these in sync with the mock interceptor handlers in
/// `lib/core/services/mock_backend/handlers/`.
class EndPoints {
  EndPoints._();

  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authForgot = '/auth/forgot-password';
  static const String authReset = '/auth/reset-password';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authRefresh = '/auth/refresh';

  // Profile
  static const String usersProfile = '/users/profile';
}
