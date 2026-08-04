import 'package:adhan/adhan.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_timings.dart';
import 'package:quran/modules/prayer/domain/entities/param_prayer_times.dart';
import 'package:quran/modules/prayer/utils/prayer_method_mapper.dart';

/// Offline prayer-time astronomy via the `adhan` package — the last-resort
/// fallback under [DSRemotePrayer] and the persisted cache.
///
/// Why it exists: the adhan alarm has to arm a rolling multi-day window from a
/// killed app / headless isolate. On a cold install with no connectivity, or
/// once the pre-fetched cache window runs dry, the remote path yields nothing
/// and the user would get silence at prayer time. Local calculation always
/// produces an answer from coordinates alone.
///
/// Lets exceptions bubble (data-source convention) — `RImplPrayer` converts.
class DSPrayerCalc {
  /// Computes the six timings for [p]'s date and coordinates.
  ///
  /// Country minute adjustments are applied here too, so a locally-computed day
  /// lines up with a cached remote day for the same country.
  MPrayerTimings timings(ParamPrayerTimes p) {
    final day = p.date ?? DateTime.now();
    final times = PrayerTimes(
      Coordinates(p.latitude, p.longitude),
      DateComponents(day.year, day.month, day.day),
      PrayerMethodMapper.parametersForMethod(p.method, p.school),
    );

    final offsets = PrayerMethodMapper.adjustmentsForCountry(p.countryCode);
    DateTime shift(DateTime t, String key) =>
        t.add(Duration(minutes: offsets[key] ?? 0));

    return MPrayerTimings(
      fajr: shift(times.fajr, 'fajr'),
      sunrise: shift(times.sunrise, 'sunrise'),
      dhuhr: shift(times.dhuhr, 'dhuhr'),
      asr: shift(times.asr, 'asr'),
      maghrib: shift(times.maghrib, 'maghrib'),
      isha: shift(times.isha, 'isha'),
      timezone: DateTime.now().timeZoneName,
    );
  }
}
