import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_prayer_settings.g.dart';

/// User-tunable prayer preferences. Single record (key = 0) in
/// `BoxPrayerSettings`.
///
/// This is the persistence shape only. The domain works in `EPrayerSettings`,
/// which `BoxPrayerSettings` maps to and from — so enums never leak their
/// stored indices into cubits or widgets, and a field added here can't ripple
/// through the app.
///
/// Every calculation field defaults to the safe answer, which is what an
/// existing install migrates onto: Aladhan picks the authority, standard Asr,
/// the API's own high-latitude behaviour, no minute corrections.
@HiveType(typeId: HiveTypeIds.prayerSettings)
class MPrayerSettings extends HiveObject {
  MPrayerSettings({
    this.calculationMethodIndex = 1,
    this.madhabIndex = 0, // standard (Shafi'i) Asr by default
    this.notifyForPrayer = const [true, true, true, true, true, false],
    this.adhanIdPerPrayer,
    this.fajrAdhanId,
    this.preNotifyMinutesPerPrayer,
    this.calculationModeIndex = 0, // automatic
    this.manualMethodId,
    this.highLatitudeRuleIndex = 0, // API default
    this.tuneMinutes,
    this.resolvedMethodId,
    this.resolvedMethodName,
  });

  /// Dead: an index into the `adhan` package's CalculationMethod enum, from
  /// when the app pinned one convention for everybody.
  ///
  /// The authority now comes from Aladhan (or [manualMethodId]), so nothing
  /// reads this. It stays declared so records written by older builds still
  /// decode — removing a `@HiveField` does not remove it from the bytes
  /// already on disk. Superseded by [calculationModeIndex] + [manualMethodId];
  /// do not add a reader.
  @HiveField(0)
  int calculationMethodIndex;

  /// Asr school: 0 = standard (Shafi'i/Maliki/Hanbali), 1 = Hanafi.
  ///
  /// Kept on its original field so a user who already chose Hanafi keeps it
  /// through the upgrade.
  @HiveField(1)
  int madhabIndex;

  /// Index of the sunrise alert in [notifyForPrayer], and the list's full
  /// length.
  ///
  /// Named here rather than written as a bare 5 at each of the four places that
  /// need it. One of them — a `index > 4` bounds check in `togglePrayer` —
  /// silently swallowed every sunrise toggle, and a literal in a guard is
  /// exactly the kind of thing that does not turn up when the slot is added
  /// somewhere else.
  static const int sunriseIndex = 5;
  static const int slotCount = 6;

  /// One bool per alert in fajr/dhuhr/asr/maghrib/isha/**sunrise** order.
  ///
  /// Sunrise is last rather than in clock order, and off by default, because it
  /// was added after the five: an install written before it exists holds a
  /// five-element list, and every reader here bounds-checks, so the missing
  /// slot reads as off. Putting it in clock order instead would have silently
  /// re-pointed every stored flag by one on upgrade — dhuhr's setting landing
  /// on asr, and so on down the list.
  ///
  /// Off by default on purpose: sunrise is not a salah, and an upgrade should
  /// not start alerting anybody at dawn without being asked.
  @HiveField(2)
  List<bool> notifyForPrayer;

  /// Override adhan per prayer (null → use default).
  /// Keys: 'fajr','dhuhr','asr','maghrib','isha'.
  @HiveField(3)
  Map<String, String>? adhanIdPerPrayer;

  /// Optional Fajr-specific adhan override.
  @HiveField(4)
  String? fajrAdhanId;

  /// Per-prayer "remind me X minutes before" offset, keyed by prayer
  /// ('fajr','dhuhr','asr','maghrib','isha'). A missing key (or 0) = off. Set
  /// independently from each prayer's picker, so Fajr's pre-alert never leaks
  /// onto the other prayers.
  @HiveField(5)
  Map<String, int>? preNotifyMinutesPerPrayer;

  /// 0 = automatic (Aladhan chooses from the coordinates), 1 = manual.
  ///
  /// Defaults to automatic, and an older record with no value for this field
  /// decodes to automatic too — which is the migration: existing users get the
  /// authority for wherever they actually are, without being asked.
  @HiveField(6)
  int calculationModeIndex;

  /// The authority the user pinned, kept even while the mode is automatic so
  /// switching back restores their choice. Never sent in automatic mode.
  @HiveField(7)
  int? manualMethodId;

  /// Index into `EHighLatitudeRule` — 0 = leave it to the API.
  @HiveField(8)
  int highLatitudeRuleIndex;

  /// Nine minute corrections in Aladhan `tune` order (Imsak, Fajr, Sunrise,
  /// Dhuhr, Asr, Maghrib, Sunset, Isha, Midnight). Null/absent = all zero.
  @HiveField(9)
  List<int>? tuneMinutes;

  /// The authority Aladhan actually used on the last successful fetch.
  ///
  /// Stored because in automatic mode it is the only way to tell the user
  /// which authority their times come from — and the only sensible input for
  /// the offline calculation fallback, which would otherwise guess.
  @HiveField(10)
  int? resolvedMethodId;

  @HiveField(11)
  String? resolvedMethodName;
}
