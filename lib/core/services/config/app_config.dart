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

  /// Whether the account UI shows: the profile card atop Settings and the
  /// profile button on the Home header — the only ways into sign-in and
  /// registration. Hidden until accounts go live; flip to bring both back.
  static const bool showAccount = false;

  /// Used as the Dio base URL. With [useMockBackend] true, the host is never
  /// hit — the [MockInterceptor] resolves matching requests locally.
  static const String apiBaseUrl = 'https://api.quran.app';

  /// Connect/receive timeouts (in milliseconds). Tuned for mobile networks.
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 20000;

  /// Google Maps Platform key, used for the Places API (New) nearby-mosques
  /// lookup (see `DSRemoteMosques`) and handed to the native Maps SDK for the
  /// mosques map (see `MapsSdk`).
  ///
  /// Never committed — supplied at build time as `GOOGLE_MAPS_API_KEY`:
  /// - locally: `flutter run --dart-define-from-file=dart_defines.json`
  ///   (gitignored file holding `{"GOOGLE_MAPS_API_KEY": "…"}`)
  /// - Codemagic: the pre-build script swaps this lookup for the key held in
  ///   the secure `GOOGLE_MAPS_API_KEY` environment variable.
  ///
  /// Empty when neither ran; the mosques screen then shows its error state.
  /// Restrict the key in the Cloud Console to Places API (New), Maps SDK for
  /// Android and Maps SDK for iOS, plus the app signatures — it is still
  /// readable from the app binary. Leaving a Maps SDK out renders the map as
  /// grey tiles behind the Google logo.
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// How a shared ayah signs itself. The badge is printed on the share card and
  /// appended to shared text whenever the reader leaves it on, so it is the one
  /// place the app speaks in its own name outside the app.
  static const String shareAppNameAr = 'ذِكر';
  static const String shareAppNameEn = 'Zikr';

  /// Where the badge sends whoever receives the share, and the link the
  /// Settings › Share the app message carries. It goes out on every shared
  /// verse, so it is the app's website rather than one store.
  static const String shareAppUrl = websiteUrl;

  // ── Settings › Contact us ────────────────────────────────────────────────

  static const String websiteUrl = 'https://www.Zikrapp.app';

  /// Also quoted by the privacy policy (`assets/legal/privacy_*.md`) — change
  /// both together.
  static const String supportEmail = 'support@Zikrapp.app';

  static const String facebookUrl = 'https://www.facebook.com/Zikrapp';
  static const String instagramHandle = 'zikrapp';
  static const String instagramUrl = 'https://www.instagram.com/$instagramHandle';

  // ── Settings › Rate the app ──────────────────────────────────────────────

  /// The Play listing — the Android application id.
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.zikr.mapp';

  /// The numeric App Store id (App Store Connect › App Information › Apple ID).
  ///
  /// TODO: fill in once the app is created on App Store Connect — until then
  /// the rate button on iOS says the store page isn't available yet.
  static const String appStoreId = '';

  /// The App Store's write-a-review page, or null while [appStoreId] is unset.
  static String? get appStoreReviewUrl =>
      appStoreId.isEmpty ? null : 'https://apps.apple.com/app/id$appStoreId?action=write-review';
}
