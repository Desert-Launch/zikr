import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One-time initialisation of the IANA timezone database, plus the lookups
/// that turn an Aladhan `meta.timezone` string (`Africa/Cairo`,
/// `America/New_York`, …) into a real [tz.Location].
///
/// Prayer times are wall-clock values *at the requested coordinates*, not at
/// the device. Attaching them to a plain `DateTime` would silently bind them
/// to the device's zone — correct while the two agree, an hour out the moment
/// they don't (a traveller whose phone hasn't caught up, a DST boundary that
/// falls between the fetch and the prayer). Materialising them as
/// [tz.TZDateTime] in the location's own zone keeps both readings right: the
/// wall clock a mosque would announce, and the absolute instant a notification
/// has to fire at.
///
/// [ensureInitialised] is safe to call from anywhere, any number of times —
/// `NotificationsService.init()` runs after the first frame, and prayer data is
/// parsed before that.
class AppTimezone {
  AppTimezone._();

  static bool _initialised = false;

  /// Loads the tz database once per isolate. Cheap after the first call.
  static void ensureInitialised() {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    _initialised = true;
  }

  /// The [tz.Location] for an IANA [id], or null when the id is empty or not in
  /// the database (a malformed/absent `meta.timezone`).
  static tz.Location? tryLocation(String? id) {
    if (id == null || id.isEmpty) return null;
    ensureInitialised();
    try {
      return tz.getLocation(id);
    } catch (_) {
      return null;
    }
  }

  /// [tryLocation] with the device's own zone as the fallback. Used where a
  /// missing zone must not stop prayer times from rendering at all — the times
  /// are then only as right as the device's clock, which is the pre-existing
  /// behaviour rather than a regression.
  static tz.Location resolve(String? id) {
    ensureInitialised();
    return tryLocation(id) ?? tz.local;
  }

  /// Builds the instant at which `hour:minute` reads on the wall clock of
  /// [location] on the given calendar day.
  static tz.TZDateTime at(
    tz.Location location, {
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
  }) => tz.TZDateTime(location, year, month, day, hour, minute);
}
