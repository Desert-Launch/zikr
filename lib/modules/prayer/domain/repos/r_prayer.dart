import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_calendar.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_day.dart';

/// The app's prayer-times contract. Aladhan is one implementation of it, not
/// the definition of it — a locally-calculated provider, a country-specific
/// authority or a self-hosted service can be swapped in behind this without
/// the cubits, the scheduler or the UI changing.
///
/// Everything returns `Either<Failure, T>`: data sources let exceptions
/// bubble, the implementation catches and converts.
abstract interface class RPrayer {
  /// One month of timings, resolved through the cache-first policy: fresh
  /// cache → network → stale cache → on-device calculation.
  Future<Either<Failure, EPrayerCalendar>> getCalendar(ParamPrayerCalendar p);

  /// A single day, served from the month that contains it wherever possible.
  Future<Either<Failure, EDailyPrayerTimes>> getDay(ParamPrayerDay p);

  /// The calculation authorities the provider supports. Cached locally; the
  /// live list is the source of truth.
  Future<Either<Failure, List<ECalculationMethod>>> getCalculationMethods();
}
