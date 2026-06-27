/// A Haramain live broadcast backed by an official Saudi YouTube channel.
///
/// Plays a specific live [videoId] via the privacy-enhanced embed. We do NOT
/// use the `live_stream?channel=…` follow endpoint: it is deprecated and YouTube
/// returns "video unavailable / error 152" for it. The [videoId]s come from
/// YouTube's own Share → Embed dialog (only offered when embedding is allowed),
/// so they play in-app.
///
/// ⚠️ When a broadcast ends and the channel starts a NEW live video, update the
/// matching [videoId] below (grab it from the stream's Share → Embed). The
/// [channelId] is kept for reference and to build the external watch fallback.
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

  /// Current live video id for this stream.
  final String videoId;

  /// Primary in-app embed (privacy-enhanced, embeddable specific video).
  /// `controls=0` for an immersive surface — the app chrome overlays instead.
  String get embedUrl =>
      'https://www.youtube-nocookie.com/embed/$videoId'
      '?autoplay=1&playsinline=1&controls=0&rel=0&fs=0&iv_load_policy=3';

  /// Watch page — loaded in-WebView on hard failure, and opened externally as a
  /// last resort.
  String get fallbackUrl => 'https://www.youtube.com/watch?v=$videoId';

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

  /// Ordered for the toggle — Makkah is the default (first).
  static const List<ELiveChannel> all = [makkah, madinah];
}
