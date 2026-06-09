import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';

/// Talks to the free Aladhan timings API. Uses its OWN [Dio] (not the shared
/// [BaseDio]) so the app's Authorization header and mock interceptor never
/// touch a third-party host. Lets exceptions bubble — the repo converts them.
class DSRemotePrayer {
  DSRemotePrayer()
      : _dio = Dio(BaseOptions(
          baseUrl: EndPoints.aladhanBase,
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
          responseType: ResponseType.json,
        ));

  final Dio _dio;

  /// `GET /v1/timings/{dd-MM-yyyy}` (or `/v1/timings` for today). Returns the
  /// `data` node of the response.
  Future<Map<String, dynamic>> timings(ParamPrayerTimes p) async {
    final date = p.date;
    final path = date != null
        ? '${EndPoints.aladhanTimings}/${DateFormat('dd-MM-yyyy').format(date)}'
        : EndPoints.aladhanTimings;

    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'method': p.method,
        'school': p.school,
      },
    );

    final body = res.data ?? const {};
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException('Aladhan response missing "data" node');
    }
    return data.cast<String, dynamic>();
  }
}
