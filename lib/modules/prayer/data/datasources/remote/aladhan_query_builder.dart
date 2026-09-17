import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// The one place the app's prayer settings become Aladhan query parameters.
///
/// Everything above the data layer speaks in enums; the numbers Aladhan wants
/// exist only here and in the tests that pin them. That is what keeps a magic
/// `school: 1` from spreading into a widget, and what makes swapping the
/// provider a change to one file.
///
/// The values were confirmed against live `/v1/timings` responses rather than
/// assumed — the response echoes back `meta.school`,
/// `meta.latitudeAdjustmentMethod` and `meta.offset`, so each mapping below is
/// observable.
class AladhanQueryBuilder {
  AladhanQueryBuilder._();

  /// `school`: 0 = Standard (Shafi'i/Maliki/Hanbali), 1 = Hanafi.
  static int schoolValue(EAsrSchool school) =>
      switch (school) { EAsrSchool.standard => 0, EAsrSchool.hanafi => 1 };

  /// `latitudeAdjustmentMethod`: 1 = Middle of the Night, 2 = One Seventh,
  /// 3 = Angle Based. Null in [EHighLatitudeRule.automatic] — the parameter is
  /// then omitted and Aladhan applies its own default.
  static int? highLatitudeValue(EHighLatitudeRule rule) => switch (rule) {
    EHighLatitudeRule.automatic => null,
    EHighLatitudeRule.middleOfTheNight => 1,
    EHighLatitudeRule.oneSeventh => 2,
    EHighLatitudeRule.angleBased => 3,
  };

  /// Builds the query for a timings/calendar request.
  ///
  /// Three omissions are deliberate, and each one is a bug if it stops being
  /// true:
  ///
  ///  * **no `method` in automatic mode** — that is what makes Aladhan choose
  ///    the authority closest to the coordinates. Sending the user's last
  ///    manual pick here would pin "Automatic" to wherever they used to live.
  ///  * **no `latitudeAdjustmentMethod` unless chosen** — so the default
  ///    behaviour is Aladhan's, not ours.
  ///  * **no `tune` when every adjustment is zero** — an untouched install
  ///    sends exactly what it sent before the setting existed.
  ///
  /// No timezone is sent either: Aladhan resolves it from the coordinates and
  /// returns it in `meta.timezone`, which is the only DST-correct source we
  /// have. Forcing `timezonestring=UTC` here would hand back UTC clock values
  /// that look like local prayer times.
  static Map<String, dynamic> build({
    required double latitude,
    required double longitude,
    required EPrayerSettings settings,
  }) {
    final methodId = settings.effectiveMethodId;
    final highLatitude = highLatitudeValue(settings.highLatitudeRule);
    return {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'school': schoolValue(settings.asrSchool).toString(),
      if (methodId != null) 'method': methodId.toString(),
      if (highLatitude != null)
        'latitudeAdjustmentMethod': highLatitude.toString(),
      if (!settings.adjustments.isZero) 'tune': settings.adjustments.tuneParam,
    };
  }
}
