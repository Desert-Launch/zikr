import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_reminder.g.dart';

/// One user-created reminder. Stored in `BoxReminders` keyed by [id]; the
/// matching local notification uses the same id (hashed to int via [notifId]).
@HiveType(typeId: HiveTypeIds.reminder)
class MReminder extends HiveObject {
  MReminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.body = '',
    this.enabled = true,
    this.iconId = 2,
    this.colorId = 3,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  int hour;

  @HiveField(4)
  int minute;

  /// 7-element bool list (Sunday..Saturday). All-true means daily.
  @HiveField(5)
  List<bool> daysOfWeek;

  @HiveField(6)
  bool enabled;

  @HiveField(7)
  DateTime createdAt;

  /// Index into [ReminderStyles.iconAssets]. Defaults to the clock icon.
  @HiveField(8)
  int iconId;

  /// Index into [ReminderStyles.colors]. Defaults to brand green.
  @HiveField(9)
  int colorId;

  /// Stable notification id for the daily-repeat case, derived from [id].
  ///
  /// The band is 7_000_000..7_999_999 — clear of prayer (1000+), hourly (5000+)
  /// and the adhan window (200000..399999). It used to be only 1000 wide
  /// (`7000 + hash % 1000`), which with the 30-reminder cap gave roughly a 1-in-3
  /// chance that two reminders hashed to the same id: they then shared one
  /// alarm, so saving or deleting either silently cancelled the other's
  /// notification. A million buckets makes that collision negligible.
  int get notifId => 7000000 + (id.hashCode.abs() % 1000000);

  /// Distinct id for a single weekday's repeat (DateTime.monday..sunday → 1..7),
  /// so a "Mon + Wed" reminder schedules two independent alarms. Lives in the
  /// 70_000_001..79_999_997 band, away from the daily-repeat ids.
  int weeklyNotifId(int weekday) => notifId * 10 + weekday;

  /// The pre-widening ids this reminder may still own on an existing install.
  /// Only ever cancelled — alarms registered under the old scheme would
  /// otherwise fire forever with no way to reach them.
  int get _legacyNotifId => 7000 + (id.hashCode.abs() % 1000);

  bool get isDaily => daysOfWeek.every((d) => d);

  /// The DateTime weekdays (1=Mon..7=Sun) this reminder fires on, derived from
  /// the Sunday..Saturday [daysOfWeek] mask (index 0 = Sunday → DateTime.sunday).
  List<int> get scheduledWeekdays {
    final out = <int>[];
    for (var i = 0; i < daysOfWeek.length && i < 7; i++) {
      if (daysOfWeek[i]) out.add(i == 0 ? DateTime.sunday : i);
    }
    return out;
  }

  /// Every notification id this reminder could own (daily + each weekday, under
  /// both the current and the legacy id scheme). Used when cancelling so no
  /// stale alarm survives a day-mask change, a time change, or the id widening.
  List<int> get allNotifIds => [
    notifId,
    for (var w = DateTime.monday; w <= DateTime.sunday; w++) weeklyNotifId(w),
    _legacyNotifId,
    for (var w = DateTime.monday; w <= DateTime.sunday; w++)
      _legacyNotifId * 10 + w,
  ];
}
