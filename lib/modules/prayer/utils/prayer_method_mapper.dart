import 'package:adhan/adhan.dart';

/// Maps an ISO-2 country code to the Aladhan numeric `method` (calculation
/// convention) and supplies any country-specific minute adjustments applied
/// after the API response.
///
/// Aladhan does the astronomy on the happy path; we only pick the convention
/// the country officially uses. [parametersForMethod] translates the same
/// numeric method onto the `adhan` package so [DSPrayerCalc] can reproduce the
/// times locally when the network and cache both miss. Falls back to Muslim
/// World League (3) for anything unmapped.
class PrayerMethodMapper {
  PrayerMethodMapper._();

  /// Muslim World League — the safe default when the country is unknown.
  static const int defaultMethod = 3;

  static const Map<String, int> _byCountry = {
    'EG': 5, // Egyptian General Authority
    'SA': 4, // Umm al-Qura (Saudi Arabia)
    'AE': 16, // Dubai / UOII
    'QA': 10, // Qatar
    'KW': 9, // Kuwait
    'BH': 8, // Bahrain
    'OM': 8, // Oman (Gulf region)
    'TN': 18, // Tunisia
    'DZ': 19, // Algeria
    'MA': 21, // Morocco / Awqaf
    'JO': 23, // Jordan
    'TR': 13, // Turkey / Diyanet
    'RU': 14, // Russia / DUMRT
    'IR': 7, // Jafari (Iran)
    'PK': 1, // Karachi
    'IN': 1, // Karachi
    'BD': 1, // Karachi
    'SG': 11, // Singapore
    'MY': 17, // Malaysia / JAKIM
    'ID': 20, // Indonesia / Kemenag
    'FR': 12, // France / UOII
    'PT': 22, // Portugal
  };

  /// Returns the Aladhan method for [countryCode] (case-insensitive), or
  /// [defaultMethod] when null/unmapped.
  static int methodForCountry(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return defaultMethod;
    return _byCountry[countryCode.toUpperCase()] ?? defaultMethod;
  }

  /// Per-prayer minute offsets applied to the API response for certain
  /// countries. Keys: 'fajr','asr','maghrib','isha'. Empty when none apply.
  static Map<String, int> adjustmentsForCountry(String? countryCode) {
    if (countryCode?.toUpperCase() == 'QA') {
      return const {'fajr': -1, 'asr': 2, 'maghrib': 1, 'isha': 1};
    }
    return const {};
  }

  /// Translates an Aladhan numeric [method] into `adhan`-package calculation
  /// parameters for the OFFLINE fallback path.
  ///
  /// The `adhan` package ships a named convention for only some of Aladhan's
  /// 23 methods. The rest are reproduced through [CalculationMethod.other]
  /// with the convention's published Fajr/Isha sun angles (or Isha interval),
  /// which is what the named conventions themselves are. Anything unrecognised
  /// falls back to Muslim World League.
  ///
  /// This path only runs when the network AND the persisted cache both miss,
  /// so a minute of drift from the API on an exotic convention is an
  /// acceptable trade for still firing the adhan at all.
  static CalculationParameters parametersForMethod(int method, int school) {
    final params = switch (method) {
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
      13 => CalculationMethod.turkey.getParameters(),
      15 => CalculationMethod.moon_sighting_committee.getParameters(),
      16 => CalculationMethod.dubai.getParameters(),
      12 => _angles(12, 12), // UOIF (France)
      14 => _angles(16, 15), // Spiritual Admin. of Muslims of Russia
      17 => _angles(20, 18), // JAKIM (Malaysia)
      18 => _angles(18, 18), // Tunisia
      19 => _angles(18, 17), // Algeria
      20 => _angles(20, 18), // Kemenag (Indonesia)
      21 => _angles(19, 17), // Morocco / Awqaf
      22 => _angles(18, 17), // Portugal
      23 => _angles(18, 18), // Jordan
      _ => CalculationMethod.muslim_world_league.getParameters(),
    };
    // Aladhan `school`: 0 = Shafi (standard), 1 = Hanafi. Same split as the
    // package's Madhab, which only changes the Asr shadow ratio.
    params.madhab = school == 1 ? Madhab.hanafi : Madhab.shafi;
    // Keeps Fajr/Isha bounded where the sun never reaches the required angle.
    // Matches Aladhan's own default high-latitude handling closely enough that
    // the fallback doesn't produce absurd times above ~48° latitude.
    params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    return params;
  }

  static CalculationParameters _angles(double fajr, double isha) =>
      CalculationParameters(fajrAngle: fajr, ishaAngle: isha);
}
