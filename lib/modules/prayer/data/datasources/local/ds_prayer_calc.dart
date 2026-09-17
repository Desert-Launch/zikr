import 'package:adhan/adhan.dart';
import 'package:quran/core/services/time/app_timezone.dart';
import 'package:quran/modules/prayer/data/datasources/remote/aladhan_query_builder.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';
import 'package:timezone/timezone.dart' as tz;

/// On-device prayer astronomy via the `adhan` package — the last resort under
/// the network and every cache.
///
/// Why it exists: the adhan alarm has to arm a rolling multi-day window from a
/// killed app or a headless isolate. On a cold install with no connectivity,
/// or once the cached months run dry, the remote path yields nothing and the
/// user would get silence at prayer time. Local calculation always produces an
/// answer from coordinates alone.
///
/// It is explicitly NOT the primary source and never overwrites the cache: the
/// API is authoritative, and a locally-computed day must not pin the app to an
/// approximation once a connection comes back.
///
/// Lets exceptions bubble (data-source convention) — `RImplPrayer` converts.
class DSPrayerCalc {
  DSPrayerCalc();

  /// Muslim World League — what the fallback uses when nothing has told it
  /// which authority applies here yet. Not a claim about the location; just
  /// the most widely applicable convention to be approximately right with.
  static const int defaultMethodId = 3;

  /// Computes one day at [latitude]/[longitude] under [settings].
  ///
  /// [resolvedMethodId] is the authority Aladhan last reported for this
  /// location, so an offline day matches the online ones the user has already
  /// seen. In manual mode the pinned method wins; with neither, MWL.
  ///
  /// [timezone] is the IANA zone last resolved for these coordinates. Given
  /// one, the result carries the same zone the cached online days do; without
  /// one it falls back to the device's, which is the best available guess.
  EDailyPrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required EPrayerSettings settings,
    int? resolvedMethodId,
    String? timezone,
  }) {
    final methodId =
        settings.effectiveMethodId ?? resolvedMethodId ?? defaultMethodId;
    final times = PrayerTimes(
      Coordinates(latitude, longitude),
      DateComponents(date.year, date.month, date.day),
      _parametersFor(methodId, settings),
    );

    final location = AppTimezone.resolve(timezone);
    final tune = settings.adjustments;
    tz.TZDateTime at(DateTime value, int adjustment) =>
        tz.TZDateTime.from(value, location).add(Duration(minutes: adjustment));

    return EDailyPrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: at(times.fajr, tune.fajr),
      sunrise: at(times.sunrise, tune.sunrise),
      dhuhr: at(times.dhuhr, tune.dhuhr),
      asr: at(times.asr, tune.asr),
      maghrib: at(times.maghrib, tune.maghrib),
      isha: at(times.isha, tune.isha),
      sunset: at(times.maghrib, tune.sunset),
      timezone: timezone ?? '',
      calculationMethodId: methodId,
    );
  }

  /// Translates an Aladhan method id into `adhan`-package parameters.
  ///
  /// The package ships a named convention for only some of Aladhan's methods.
  /// The rest are reproduced through explicit Fajr/Isha sun angles — which is
  /// what the named conventions themselves are — using the angles Aladhan
  /// publishes for them on `/v1/methods`. Anything unrecognised falls back to
  /// Muslim World League.
  ///
  /// This path only runs when the network AND every cache miss, so a minute of
  /// drift from the API on an exotic convention is an acceptable trade for
  /// still calling the adhan at all.
  CalculationParameters _parametersFor(int methodId, EPrayerSettings settings) {
    final params = switch (methodId) {
      0 => _angles(16, 14), // Jafari — Shia Ithna-Ashari, Qum
      1 => CalculationMethod.karachi.getParameters(),
      2 => CalculationMethod.north_america.getParameters(),
      3 => CalculationMethod.muslim_world_league.getParameters(),
      4 => CalculationMethod.umm_al_qura.getParameters(),
      5 => CalculationMethod.egyptian.getParameters(),
      7 => CalculationMethod.tehran.getParameters(),
      8 => CalculationMethod.dubai.getParameters(), // Gulf region
      9 => CalculationMethod.kuwait.getParameters(),
      10 => CalculationMethod.qatar.getParameters(),
      11 => CalculationMethod.singapore.getParameters(),
      12 => _angles(12, 12), // UOIF (France)
      13 => CalculationMethod.turkey.getParameters(),
      14 => _angles(16, 15), // Spiritual Admin. of Muslims of Russia
      15 => CalculationMethod.moon_sighting_committee.getParameters(),
      16 => _angles(18.2, 18.2), // Dubai
      17 => _angles(20, 18), // JAKIM (Malaysia)
      18 => _angles(18, 18), // Tunisia
      19 => _angles(18, 17), // Algeria
      20 => _angles(20, 18), // Kemenag (Indonesia)
      21 => _angles(19, 17), // Morocco
      22 => _angles(18, 17), // Portugal
      23 => _angles(18, 18), // Jordan
      _ => CalculationMethod.muslim_world_league.getParameters(),
    };
    // Same split as Aladhan's `school`: it only moves the Asr shadow ratio.
    params.madhab = AladhanQueryBuilder.schoolValue(settings.asrSchool) == 1
        ? Madhab.hanafi
        : Madhab.shafi;
    params.highLatitudeRule = _highLatitudeRule(settings.highLatitudeRule);
    return params;
  }

  /// Mirrors the user's high-latitude choice onto the package.
  ///
  /// [EHighLatitudeRule.automatic] means "whatever Aladhan does by default",
  /// which is angle-based — so the offline day matches the online ones rather
  /// than quietly using a different rule the moment the network drops.
  HighLatitudeRule _highLatitudeRule(EHighLatitudeRule rule) => switch (rule) {
    EHighLatitudeRule.automatic ||
    EHighLatitudeRule.angleBased => HighLatitudeRule.twilight_angle,
    EHighLatitudeRule.middleOfTheNight => HighLatitudeRule.middle_of_the_night,
    EHighLatitudeRule.oneSeventh => HighLatitudeRule.seventh_of_the_night,
  };

  CalculationParameters _angles(double fajr, double isha) =>
      CalculationParameters(fajrAngle: fajr, ishaAngle: isha);
}
