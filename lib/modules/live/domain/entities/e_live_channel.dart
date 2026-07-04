/// A Haramain live broadcast backed by an official Saudi YouTube channel.
///
/// The CURRENT live video id is resolved at runtime from the channel's public
/// [liveUrl] (`/channel/{id}/live`) — see `DSRemoteLive` — so the stream keeps
/// working when a broadcast ends and the channel rolls to a new live video, with
/// no code change. The resolved id is fed into the privacy-enhanced embed via
/// [embedUrlFor].
///
/// We do NOT use the `live_stream?channel=…` embed endpoint: it is deprecated and
/// YouTube returns "video unavailable / error 152" for it.
///
/// [videoId] is the last-known-good id, used ONLY as an offline / resolution
/// fallback so the surface never renders empty. It comes from YouTube's own
/// Share → Embed dialog (offered only when embedding is allowed).
class ELiveChannel {
  const ELiveChannel({
    required this.id,
    required this.titleKey,
    required this.shortTitleKey,
    required this.subtitleKey,
    required this.channelId,
    required this.videoId,
  });

  /// Internal selection key (e.g. `makkah`) — NOT the YouTube id.
  final String id;

  /// Flat, underscore-prefixed i18n keys.
  final String titleKey;
  final String shortTitleKey;
  final String subtitleKey;

  /// Official YouTube channel id (reference + external fallback).
  final String channelId;

  /// Last-known-good live video id — the resolution fallback (see class doc).
  final String videoId;

  /// The channel's public "current live" page. Reading it yields whatever video
  /// the channel is broadcasting right now (see `DSRemoteLive`).
  String get liveUrl => 'https://www.youtube.com/channel/$channelId/live';

  /// Privacy-enhanced embed for a resolved live [id] (embeddable specific video).
  /// `controls=0` for an immersive surface — the app chrome overlays instead.
  static String embedUrlFor(String id) =>
      'https://www.youtube-nocookie.com/embed/$id'
      '?autoplay=1&playsinline=1&controls=0&rel=0&fs=0&iv_load_policy=3';

  /// Watch page for a resolved live [id] — loaded in-WebView on hard failure,
  /// and opened externally as a last resort.
  static String watchUrlFor(String id) =>
      'https://www.youtube.com/watch?v=$id';

  /// Embed for the fallback [videoId] (used before resolution completes).
  String get embedUrl => embedUrlFor(videoId);

  /// Watch page for the fallback [videoId].
  String get fallbackUrl => watchUrlFor(videoId);

  /// Al-Masjid Al-Haram — KSA Qur'an TV (Saudi Broadcasting Authority).
  static const ELiveChannel makkah = ELiveChannel(
    id: 'makkah',
    titleKey: 'live_makkah',
    shortTitleKey: 'live_makkah_short',
    subtitleKey: 'live_makkah_hint',
    channelId: 'UCos52azQNBgW63_9uDJoPDA',
    videoId: 'fZvuHkHYaXk',
  );

  /// Al-Masjid An-Nabawi — KSA Sunnah TV (Saudi Broadcasting Authority).
  static const ELiveChannel madinah = ELiveChannel(
    id: 'madinah',
    titleKey: 'live_madinah',
    shortTitleKey: 'live_madinah_short',
    subtitleKey: 'live_madinah_hint',
    channelId: 'UCROKYPep-UuODNwyipe6JMw',
    videoId: 'ge2Xn-Lwk3U',
  );

  /// Ordered for the picker — Makkah is the default (first).
  static const List<ELiveChannel> all = [makkah, madinah];

  /// Resolves a channel from its selection [id] (e.g. `makkah`), falling back to
  /// [makkah] for an unknown id so the player always has something to open.
  static ELiveChannel byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => makkah);
}
