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

  // Aladhan — prayer timings (free, no auth). Astronomical calculation is
  // done server-side; we only supply lat/lon/method/school/date.
  // Reached via a dedicated Dio in DSRemotePrayer, NOT the shared BaseDio,
  // so the app's Authorization header is never sent to a third party.
  static const String aladhanBase = 'https://api.aladhan.com/v1';
  static const String aladhanTimings = '/timings';

  // mp3quran.net — live Quran radio catalogue (free, no auth). Reached via a
  // dedicated Dio in DSRemoteRadio, NOT the shared BaseDio, so the app's
  // Authorization header is never sent to a third party.
  static const String mp3QuranBase = 'https://mp3quran.net/api/v3';
  static const String mp3QuranRadios = '/radios';

  // YouTube — resolve a channel's CURRENT live video by reading its public
  // `/live` page (free, no auth, no API key). Reached via a dedicated Dio in
  // DSRemoteLive, NOT the shared BaseDio, so the app's Authorization header is
  // never sent to a third party.
  static const String youtubeBase = 'https://www.youtube.com';
  static String youtubeChannelLive(String channelId) =>
      '/channel/$channelId/live';

  // Adhan voice catalog (host as JSON on your CDN). Lets NEW voices ship
  // without an app update. Empty = remote catalog disabled: the app uses the
  // bundled `assets/data/adhans.json` only and skips the network entirely.
  //
  // To enable: host the generated `adhan_catalog.json` (repo root) on any
  // public static host and paste its URL here, e.g.
  //   'https://cdn.yourapp.com/adhans/catalog.json'
  static const String adhanCatalog = '';
}
