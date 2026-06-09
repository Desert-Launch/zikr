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

  /// Index into [ReminderStyles.icons]. Defaults to the clock icon.
  @HiveField(8)
  int iconId;

  /// Index into [ReminderStyles.colors]. Defaults to brand green.
  @HiveField(9)
  int colorId;

  /// Stable notification id for the daily-repeat case. We reserve 7000..7999
  /// for reminders so they don't clash with prayer (1000+) or hourly (5000+).
  int get notifId => 7000 + (id.hashCode.abs() % 1000);

  /// Distinct id for a single weekday's repeat (DateTime.monday..sunday → 1..7),
  /// so a "Mon + Wed" reminder schedules two independent alarms. Lives in the
  /// 70000..79997 band, away from the daily-repeat ids.
  int weeklyNotifId(int weekday) => notifId * 10 + weekday;

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

  /// Every notification id this reminder could own (daily + each weekday).
  /// Used when cancelling so no stale alarm survives a day-mask change.
  List<int> get allNotifIds =>
      [notifId, for (var w = DateTime.monday; w <= DateTime.sunday; w++) weeklyNotifId(w)];
}
