import 'package:dio/dio.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

/// Fetches the live Quran radio catalogue from the free mp3quran.net API.
///
/// Uses its OWN [Dio] (not the shared [BaseDio]) so the app's Authorization
/// header and mock interceptor never touch a third-party host — same pattern as
/// [DSRemotePrayer]. Lets exceptions bubble; the repo converts them to Failures.
class DSRemoteRadio {
  DSRemoteRadio()
      : _dio = Dio(BaseOptions(
          baseUrl: EndPoints.mp3QuranBase,
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
          responseType: ResponseType.json,
        ));

  final Dio _dio;

  /// `GET /radios?language=ar`. Returns the parsed `radios` array (stations with
  /// an empty URL are dropped — they can't be played).
  Future<List<MRadioStation>> fetchStations({String language = 'ar'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      EndPoints.mp3QuranRadios,
      queryParameters: {'language': language},
    );

    final body = res.data ?? const {};
    final radios = body['radios'];
    if (radios is! List) {
      throw const FormatException('mp3quran response missing "radios" node');
    }

    return radios
        .whereType<Map>()
        .map((m) => MRadioStation.fromMp3Quran(m.cast<String, dynamic>()))
        .where((s) => s.url.isNotEmpty)
        .toList();
  }
}
