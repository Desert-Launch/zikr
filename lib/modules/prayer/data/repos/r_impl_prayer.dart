import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/prayer/data/datasources/remote/ds_remote_prayer.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';
import 'package:quran/modules/prayer/utils/prayer_method_mapper.dart';

class RImplPrayer implements RPrayer {
  RImplPrayer({required DSRemotePrayer remote}) : _remote = remote;

  final DSRemotePrayer _remote;

  /// In-memory day cache keyed by `{yyyy-MM-dd}_{lat3dp}_{lon3dp}_{method}`.
  final Map<String, MPrayerTimings> _memCache = {};

  @override
  Future<Either<Failure, MPrayerTimings>> getTimings(ParamPrayerTimes p) async {
    final day = p.date ?? DateTime.now();
    final key = '${day.year}-${day.month}-${day.day}'
        '_${p.latitude.toStringAsFixed(3)}'
        '_${p.longitude.toStringAsFixed(3)}'
        '_${p.method}';

    final cached = _memCache[key];
    if (cached != null) return Right(cached);

    try {
      final data = await _remote.timings(p);
      final timings = MPrayerTimings.fromJson(
        data,
        date: day,
        offsets: PrayerMethodMapper.adjustmentsForCountry(p.countryCode),
      );
      _memCache[key] = timings;
      return Right(timings);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplPrayer.getTimings',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  Failure _failureFromDio(DioException e) {
    final msg = e.message ?? 'Network error';
    final code = e.response?.statusCode;
    if (code == 404) return Failure.notFoundFailure(message: msg);
    if (code != null && code >= 500) {
      return Failure.serverFailure(message: msg, statusCode: code);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure.networkFailure(message: msg);
    }
    return Failure.unexpectedFailure(message: msg);
  }
}
