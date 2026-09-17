import 'dart:math' as math;

/// When prayer times are worth fetching again — and, just as importantly, when
/// they are not.
///
/// Prayer times change slowly and predictably, so the app fetches a month at a
/// time and then leaves the network alone. Nothing here runs on a timer, on a
/// rebuild, or on a countdown tick; every rule below answers a question some
/// caller already had.
class PrayerRefreshPolicy {
  PrayerRefreshPolicy._();

  /// How far the user has to move before their prayer times are meaningfully
  /// different.
  ///
  /// GPS noise, a walk to the shops and a commute across a city all leave the
  /// times within a minute of each other; a flight does not. 7.5 km sits in
  /// the middle of the useful band — high enough that a phone drifting between
  /// cell and GPS fixes never triggers a refetch, low enough that genuine
  /// travel does.
  static const double meaningfulDistanceMetres = 7500;

  /// How long a cached month stays "fresh" before the app tries to refresh it
  /// in the background.
  ///
  /// A month of times is stable — this is not about the numbers going stale,
  /// it is about picking up a corrected calculation or a method Aladhan has
  /// since changed for the region. A stale month is still served; it just gets
  /// a refresh attempt alongside.
  static const Duration freshFor = Duration(days: 7);

  /// How long the cached `/methods` list is reused before refetching.
  static const Duration methodsFreshFor = Duration(days: 30);

  /// Great-circle distance in metres.
  ///
  /// Written out rather than taken from `geolocator` so this stays pure Dart:
  /// the policy is exercised in unit tests, which have no platform channels.
  static double distanceBetween(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const double earthRadius = 6371000;
    double toRadians(double degrees) => degrees * math.pi / 180;

    final dLat = toRadians(latitude2 - latitude1);
    final dLon = toRadians(longitude2 - longitude1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(latitude1)) *
            math.cos(toRadians(latitude2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Whether the user has travelled far enough from where a calendar was
  /// fetched for it to no longer apply.
  static bool hasMovedMeaningfully({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) =>
      distanceBetween(
        fromLatitude,
        fromLongitude,
        toLatitude,
        toLongitude,
      ) >
      meaningfulDistanceMetres;

  /// Whether a month fetched at [fetchedAt] should be refreshed.
  static bool isStale(DateTime fetchedAt, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(fetchedAt) > freshFor;

  /// The months that must be on hand for [day]: the one it falls in, and the
  /// next.
  ///
  /// Prefetching the following month is what keeps the last day of a month —
  /// and the notification window that reaches past it — from falling off the
  /// end of the cache.
  static List<(int year, int month)> monthsToCover(DateTime day) {
    final next = DateTime(day.year, day.month + 1);
    return [(day.year, day.month), (next.year, next.month)];
  }
}
