import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/modules/prayer/data/datasources/remote/aladhan_query_builder.dart';
import 'package:quran/modules/prayer/data/models/m_aladhan_day.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// Talks to the free Aladhan API. Uses its OWN [Dio] (not the shared
/// [BaseDio]) so the app's Authorization header and mock interceptor never
/// touch a third-party host — the only thing that leaves the device here is a
/// pair of coordinates and the user's calculation preferences.
///
/// Lets exceptions bubble (data-source convention); `RImplPrayer` converts
/// them into `Failure`s and decides what to serve instead.
class DSRemotePrayer {
  DSRemotePrayer()
    : _dio = Dio(
        BaseOptions(
          baseUrl: EndPoints.aladhanBase,
          connectTimeout: const Duration(
            milliseconds: AppConfig.connectTimeoutMs,
          ),
          receiveTimeout: const Duration(
            milliseconds: AppConfig.receiveTimeoutMs,
          ),
          responseType: ResponseType.json,
        ),
      );

  final Dio _dio;

  /// `GET /calendar/{year}/{month}` — a whole month in one request.
  ///
  /// This is the endpoint the app normally uses: fetching a month at a time is
  /// what lets the prayer screen open, and the notification window rebuild,
  /// without touching the network at all.
  ///
  /// Days the API returns in a shape we can't read are skipped rather than
  /// fatal; the month is only rejected when nothing at all parsed.
  Future<List<MAladhanDay>> calendar({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required EPrayerSettings settings,
  }) async {
    final res = await _dio.get<dynamic>(
      EndPoints.aladhanCalendar(year, month),
      queryParameters: AladhanQueryBuilder.build(
        latitude: latitude,
        longitude: longitude,
        settings: settings,
      ),
    );

    final data = _unwrap(res.data);
    // Aladhan has served `data` both as a list of days and (for some
    // month/params combinations) as a map keyed by day number. Accept either.
    final nodes = switch (data) {
      final List list => list,
      final Map map => map.values.toList(),
      _ => throw const FormatException(
        'Aladhan calendar response has no day list',
      ),
    };

    final days = <MAladhanDay>[
      for (final node in nodes)
        if (MAladhanDay.tryParse(node) case final day?) day,
    ];
    if (days.isEmpty) {
      throw const FormatException('Aladhan calendar returned no usable days');
    }
    days.sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

  /// `GET /timings/{dd-MM-yyyy}` — one day. Used for a day outside the cached
  /// months; the calendar endpoint covers the normal case.
  Future<MAladhanDay> timings({
    required double latitude,
    required double longitude,
    required EPrayerSettings settings,
    DateTime? date,
  }) async {
    final path = date != null
        ? '${EndPoints.aladhanTimings}/${DateFormat('dd-MM-yyyy').format(date)}'
        : EndPoints.aladhanTimings;

    final res = await _dio.get<dynamic>(
      path,
      queryParameters: AladhanQueryBuilder.build(
        latitude: latitude,
        longitude: longitude,
        settings: settings,
      ),
    );

    final day = MAladhanDay.tryParse(_unwrap(res.data), fallbackDate: date);
    if (day == null) {
      throw const FormatException('Aladhan timings response is not a day');
    }
    return day;
  }

  /// `GET /methods` — every calculation authority Aladhan supports.
  ///
  /// The response is an object keyed by short code (`MWL`, `EGYPT`, …), not a
  /// list. `CUSTOM` is dropped: it is a placeholder for caller-supplied angles
  /// and means nothing as a pickable option.
  Future<List<ECalculationMethod>> methods() async {
    final res = await _dio.get<dynamic>(EndPoints.aladhanMethods);
    final data = _unwrap(res.data);
    if (data is! Map) {
      throw const FormatException('Aladhan methods response is not a map');
    }

    final methods = <ECalculationMethod>[
      for (final node in data.values)
        if (node is Map)
          ECalculationMethod.fromJson(node.cast<String, dynamic>()),
    ].where((m) => m.id >= 0 && m.id != ECalculationMethod.customId && m.name.isNotEmpty).toList();

    if (methods.isEmpty) {
      throw const FormatException('Aladhan methods response was empty');
    }
    methods.sort((a, b) => a.name.compareTo(b.name));
    return methods;
  }

  /// Pulls the `data` node out of an Aladhan envelope
  /// (`{code, status, data}`).
  Object? _unwrap(Object? body) {
    if (body is! Map) {
      throw const FormatException('Aladhan response is not an object');
    }
    final data = body['data'];
    if (data == null) {
      throw const FormatException('Aladhan response missing "data" node');
    }
    return data;
  }
}
