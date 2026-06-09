import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';

abstract class RPrayer {
  /// Fetches prayer timings for the given location/method/date from Aladhan,
  /// applying any country adjustments. Short-lived in-memory cache avoids
  /// duplicate calls for the same day+location within a session.
  Future<Either<Failure, MPrayerTimings>> getTimings(ParamPrayerTimes p);
}
