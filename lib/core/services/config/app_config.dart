/// Build-time configuration. Toggle [useMockBackend] to flip between the
/// in-app fake API (default in dev) and a real backend.
///
/// When [useMockBackend] is true, [MockInterceptor] short-circuits every
/// request whose path matches a registered handler and returns a canned
/// response. All other requests fall through to the real network — useful
/// for hybrid setups where only auth is mocked.
class AppConfig {
  AppConfig._();

  /// When true, registered mock routes are served from the in-app fake
  /// backend (see `lib/core/services/mock_backend/`). The rest of the app
  /// continues to use Dio normally, so a real backend can take over later
  /// by flipping this flag and pointing [apiBaseUrl] at the real server.
  static const bool useMockBackend = true;

  /// Used as the Dio base URL. With [useMockBackend] true, the host is never
  /// hit — the [MockInterceptor] resolves matching requests locally.
  static const String apiBaseUrl = 'https://api.quran.app';

  /// Connect/receive timeouts (in milliseconds). Tuned for mobile networks.
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 20000;

  /// How a shared ayah signs itself. The badge is printed on the share card and
  /// appended to shared text whenever the reader leaves it on, so it is the one
  /// place the app speaks in its own name outside the app.
  static const String shareAppNameAr = 'ذِكر';
  static const String shareAppNameEn = 'Zikr';

  /// Where the badge sends whoever receives the share.
  ///
  /// TODO: point at the real landing page once it ships — this is a
  /// placeholder, and it goes out on every shared verse.
  static const String shareAppUrl = 'https://zikr.app';
}
