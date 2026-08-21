import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_prayer_settings.g.dart';

/// User-tunable prayer-calculation preferences. Single record (key = 0) in
/// `BoxPrayerSettings`.
@HiveType(typeId: HiveTypeIds.prayerSettings)
class MPrayerSettings extends HiveObject {
  MPrayerSettings({
    this.calculationMethodIndex = 1, // egyptian by default
    this.madhabIndex = 0,            // shafi by default
    this.notifyForPrayer = const [true, true, true, true, true, false],
    this.adhanIdPerPrayer,
    this.fajrAdhanId,
    this.preNotifyMinutesPerPrayer,
  });

  /// Index into the `adhan` package's CalculationMethod enum.
  @HiveField(0)
  int calculationMethodIndex;

  /// 0 = shafi, 1 = hanafi.
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
}
