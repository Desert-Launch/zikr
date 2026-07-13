import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_notification.g.dart';

/// A single scheduled local notification, persisted so the app can reconcile
/// its schedule across restarts (survives reboots / timezone changes) and
/// re-time entries when live prayer times move.
///
/// Stored in `BoxNotifications` keyed by [id] (the same int id passed to the
/// OS scheduler, so cancel/reschedule stays symmetric).
///
/// This is a data-layer record only — it holds the raw payload as
/// [payloadType] + [payloadJson] strings so the model stays free of the
/// `NotificationPayload` type. The service reconstructs the payload when it
/// (re)schedules.
@HiveType(typeId: HiveTypeIds.scheduledNotification)
class MLocalNotification extends HiveObject {
  MLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.channelId,
    this.repeatDaily = false,
    this.weekday = 0,
    this.payloadType = '',
    this.payloadJson = '',
    this.autoSchedule = false,
    this.isEnabled = true,
  });

  /// OS scheduler id — also the Hive key.
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  /// The concrete local time this notification is (next) set to fire. For
  /// repeating notifications only the time-of-day (and [weekday]) is used by
  /// the scheduler; this timestamp records the resolved fire time for the day
  /// it was scheduled.
  @HiveField(3)
  DateTime scheduledAt;

  /// Android channel id (see [AppNotificationChannels]).
  @HiveField(4)
  String channelId;

  /// True → repeats every day at [scheduledAt]'s time-of-day.
  @HiveField(5)
  bool repeatDaily;

  /// 0 → not weekly; 1..7 (DateTime.monday..sunday) → repeats weekly on that
  /// weekday at [scheduledAt]'s time-of-day.
  @HiveField(6)
  int weekday;

  /// `NotificationPayload.type` (e.g. `azkar`, `quran`).
  @HiveField(7)
  String payloadType;

  /// JSON-encoded `NotificationPayload.data` map.
  @HiveField(8)
  String payloadJson;

  /// When true, this entry's fire time tracks live prayer times (morning azkar
  /// → Fajr+1h, evening azkar → Maghrib−15m) rather than the seed time from
  /// JSON. Only such entries are re-timed by `updateAzkarNotifications`.
  @HiveField(9)
  bool autoSchedule;

  @HiveField(10)
  bool isEnabled;

  bool get isWeekly => weekday >= DateTime.monday && weekday <= DateTime.sunday;
}
