import 'package:dio/dio.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';

/// Resolves a YouTube channel's CURRENT live video id from its public `/live`
/// page — free, no API key. When a channel is broadcasting, that page's
/// canonical link points at the live watch URL; we pull the 11-char id out of it.
///
/// Uses its OWN [Dio] (not the shared [BaseDio]) so the app's Authorization
/// header and mock interceptor never touch a third-party host — same pattern as
/// [DSRemoteRadio]. Fetches HTML (not JSON), so [ResponseType.plain]. Lets
/// exceptions bubble; the repo converts them to Failures.
class DSRemoteLive {
  DSRemoteLive()
      : _dio = Dio(BaseOptions(
          baseUrl: EndPoints.youtubeBase,
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
          responseType: ResponseType.plain,
          // A desktop UA + English locale avoids YouTube's mobile/consent
          // variants that omit the canonical link we parse.
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ));

  final Dio _dio;

  /// Preferred: the canonical watch URL YouTube injects for the live video.
  static final RegExp _canonical = RegExp(
    r'<link\s+rel="canonical"\s+href="https://www\.youtube\.com/watch\?v=([A-Za-z0-9_-]{11})"',
  );

  /// Fallback: the first player `videoId` in the page's initial data.
  static final RegExp _videoId = RegExp(r'"videoId":"([A-Za-z0-9_-]{11})"');

  /// Fetches `/channel/{channelId}/live` and returns the id of the video the
  /// channel is currently broadcasting. Throws when the page yields no id.
  Future<String> resolveLiveVideoId(String channelId) async {
    final res = await _dio.get<String>(
      EndPoints.youtubeChannelLive(channelId),
    );

    final html = res.data ?? '';
    final id =
        _canonical.firstMatch(html)?.group(1) ??
        _videoId.firstMatch(html)?.group(1);
    if (id == null || id.isEmpty) {
      throw const FormatException(
        'No live video id found on the YouTube channel /live page',
      );
    }
    return id;
  }
}
