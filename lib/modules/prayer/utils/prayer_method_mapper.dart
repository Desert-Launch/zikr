/// Maps an ISO-2 country code to the Aladhan numeric `method` (calculation
/// convention) and supplies any country-specific minute adjustments applied
/// after the API response.
///
/// There is no local calculation library — Aladhan does the astronomy. We only
/// pick the convention the country officially uses. Falls back to Muslim World
/// League (3) for anything unmapped.
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
}
