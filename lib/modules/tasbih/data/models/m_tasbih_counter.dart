import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_tasbih_counter.g.dart';

/// Live counter state. Single record (key = 0) so the user can pick up
/// where they left off across launches without losing count.
@HiveType(typeId: HiveTypeIds.tasbihCounter)
class MTasbihCounter extends HiveObject {
  MTasbihCounter({
    this.zekrAr = 'سُبْحَانَ اللَّهِ',
    this.target = 33,
    this.count = 0,
    this.vibrate = true,
    this.hourlyEnabled = true,
    this.reminderEnabled = true,
    this.reminderIntervalHours = 3,
    this.reminderHour = 9,
    this.reminderMinute = 30,
  });

  /// The phrase being counted. User can swap between سبحان الله, الحمد لله,
  /// الله أكبر, etc. — see SNTasbih for the list.
  @HiveField(0)
  String zekrAr;

  /// Target count for the current session — typically 33, 99, or 100.
  @HiveField(1)
  int target;

  /// Live count — increments on each tap, resets when the user taps reset.
  @HiveField(2)
  int count;

  /// Haptic feedback on tap.
  @HiveField(3)
  bool vibrate;

  /// Whether hourly tasbih notifications fire 08–22 (Decision 2). On by default
  /// so a fresh install starts receiving them without visiting SNTasbihHourly.
  /// Installs that predate this default are seeded once by
  /// [DSHourlyTasbih.seedDefaultIfNeeded].
  @HiveField(4)
  bool hourlyEnabled;

  /// Salawat reminder fields — only meaningful on the salawat record
  /// (see [BoxTasbihCounter.salawatKey]); harmless defaults on the tasbih one.
  ///
  /// Whether the salawat-upon-the-Prophet reminder is scheduled. On by default
  /// so a fresh install starts receiving it without visiting the settings sheet
  /// (see `DSSalawatReminder.rescheduleFromSettings`).
  @HiveField(5)
  bool reminderEnabled;

  /// Hours between reminders within the 08:00–22:00 window — 3 by default. `0`
  /// switches to a single daily reminder at [reminderHour]:[reminderMinute].
  @HiveField(6)
  int reminderIntervalHours;

  /// Hour (0–23) for the single specific-time reminder (when interval is 0).
  @HiveField(7)
  int reminderHour;

  /// Minute (0–59) for the single specific-time reminder (when interval is 0).
  @HiveField(8)
  int reminderMinute;
}
