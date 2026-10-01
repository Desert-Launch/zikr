import 'package:dio/dio.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/modules/mosques/data/models/m_mosque.dart';

/// Finds mosques around a point through the Google Places API (New)
/// `places:searchNearby` endpoint.
///
/// Uses its OWN [Dio] (not the shared [BaseDio]) so the app's Authorization
/// header and mock interceptor never touch a third-party host — same pattern as
/// [DSRemoteLive]. The API key and field mask travel as headers. Lets
/// exceptions bubble; the repo converts them to Failures.
class DSRemoteMosques {
  DSRemoteMosques()
      : _dio = Dio(BaseOptions(
          baseUrl: EndPoints.googlePlacesBase,
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
          headers: const {
            'X-Goog-Api-Key': AppConfig.googleMapsApiKey,
            // Billing follows the fields asked for: these four are all the
            // list needs (no phone, no opening hours).
            'X-Goog-FieldMask': 'places.id,places.displayName,'
                'places.shortFormattedAddress,places.location',
          },
        ));

  final Dio _dio;

  /// The API's ceilings. Ranking by distance means the widest circle still
  /// returns the nearest results first, so one request covers both a dense
  /// city and a rural area where the closest mosque is kilometres away.
  static const double _radiusMeters = 50000;
  static const int _maxResults = 20;

  /// Up to [_maxResults] mosques nearest to ([latitude], [longitude]).
  Future<List<MMosque>> searchNearby({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    if (AppConfig.googleMapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY is not set — run with '
        '--dart-define-from-file=dart_defines.json',
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      EndPoints.googlePlacesSearchNearby,
      data: {
        'includedTypes': ['mosque'],
        'maxResultCount': _maxResults,
        'rankPreference': 'DISTANCE',
        'languageCode': languageCode,
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': _radiusMeters,
          },
        },
      },
    );

    // Google leaves `places` out entirely (an empty object) when nothing
    // matched, rather than sending an empty list.
    final places = res.data?['places'];
    if (places is! List) return const [];
    return places
        .whereType<Map<String, dynamic>>()
        .map(MMosque.tryParse)
        .whereType<MMosque>()
        .toList();
  }
}
