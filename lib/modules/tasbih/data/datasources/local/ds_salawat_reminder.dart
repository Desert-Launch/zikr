import 'dart:io';

import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notification_slots.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/notifications/reminder_sound_alarms.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';

/// Schedules the "salawat upon the Prophet ﷺ" reminders. Two modes:
///
///  * **Interval** — fires every `intervalHours` across the user's reminder
///    window (`BoxAppSettings.reminderWindow`, 08:00–22:00 until they change
///    it; the install default is every 3h → 08, 11, 14, 17, 20). The minute
///    defaults to
///    `:30` so it never lands on the `:00` boundary shared by the hourly tasbih
///    and the azkar/quran feeds.
///  * **Specific time** — a single daily reminder at the user's chosen
///    `hour:minute`.
///
/// **Conflict avoidance:** [reservedTimes] are slots already claimed by the
/// prayer and azkar/quran feeds. A reminder that collides is nudged to the next
/// free minute candidate (keeping [NotificationSlots.gapMinutes] between them),
/// so two notifications never arrive on top of each other. Only the minute
/// moves —
/// the id (`_hourBase + hour`) stays stable so cancel/reschedule is symmetric.
/// The hourly zekr is placed *after* salawat and treats these times as reserved
/// in turn — see `AdhanScheduler.reconcileCompanionNotifications`.
///
/// Each reminder plays the bundled salawat clip via
/// [AppNotificationChannels.salawat] (Android) / [_iosSound] (iOS).
///
/// **"Remind while silenced"** (`MAppSettings.salawatIgnoreSilent`) is not a
/// different channel sound but a different *source* of sound: the notification
/// moves to the silent [AppNotificationChannels.salawatSilent] and the clip is
/// played by the app itself through [ReminderSoundAlarms], on the ALARM stream.
/// A channel sound — even an alarm-attributed one — is dropped outright by One
/// UI's Mute mode, which is exactly the case the toggle exists for. iOS has no
/// equivalent: only a critical alert pierces the Ring/Silent switch, and this
/// app's entitlement request scopes that to the adhan alone, so there the
/// reminder is merely marked time-sensitive (which clears Focus, not silent).
///
/// Notification IDs reserved: 5099 (specific time) + 5100..5123 (one per hour
/// of the day) — clear of the hourly tasbih block (5000..5023).
class DSSalawatReminder {
  DSSalawatReminder(
    this._notifications,
    this._counter,
    this._appSettings, [
    ReminderSoundAlarms? sound,
  ]) : _sound = sound ?? ReminderSoundAlarms();

  final NotificationsService _notifications;
  final BoxTasbihCounter _counter;
  final BoxAppSettings _appSettings;
  final ReminderSoundAlarms _sound;

  /// iOS notification sound — the CAF copy of `salah_3la_mohamed.mp3` bundled
  /// in `ios/Runner/Sounds/`.
  static const _iosSound = 'salah_3la_mohamed.caf';

  /// Android raw resource (`res/raw/salah_3la_mohamed.mp3`) — the same clip,
  /// played by [ReminderSoundAlarms] in "remind while silenced" mode.
  static const _androidClip = 'salah_3la_mohamed';

  /// Preferred minutes, in order. `:30` first (offset from the hourly tasbih's
  /// `:00`); the rest are fallbacks used only when a reserved time collides.
  static const _minuteCandidates = [30, 35, 25, 40, 20, 45, 15, 50, 10];

  /// ID for the single specific-time reminder.
  static const _specificId = 5099;

  /// Base for the per-hour interval reminders (id = [_hourBase] + hour).
  static const _hourBase = 5100;

  /// Times claimed by the other feeds on the last coordinated run. Cached so a
  /// UI-triggered toggle (which carries no prayer-time context) still places
  /// the reminders around the known prayer / azkar slots rather than falling
  /// back to a naive `:30`.
  List<DateTime> _lastReserved = const [];

  /// Today's fire times for the currently configured reminders — handed to the
  /// hourly zekr so it can steer clear of them. Empty when disabled.
  List<DateTime> occupiedTimesToday() {
    final c = _counter.current(BoxTasbihCounter.salawatKey);
    if (!c.reminderEnabled) return const [];
    final now = DateTime.now();
    final slots = _slotsFor(
      c.reminderIntervalHours,
      c.reminderHour,
      c.reminderMinute,
      _lastReserved,
    );
    return [
      for (final (_, hour, minute) in slots)
        DateTime(now.year, now.month, now.day, hour, minute),
    ];
  }

  /// (Re)schedules from the persisted settings, avoiding [reservedTimes], and
  /// returns the times it placed so the caller can pass them on as reserved to
  /// the next feed. Beyond clearing the old schedule this is a no-op when the
  /// user has the reminder switched off.
  ///
  /// This is the boot / reconciliation entry point — the schedule self-heals on
  /// every launch, and on a fresh install it seeds the default (enabled, every
  /// 3h) straight from [BoxTasbihCounter].
  Future<List<DateTime>> rescheduleFromSettings({
    List<DateTime> reservedTimes = const [],
  }) async {
    _lastReserved = reservedTimes;
    final c = _counter.current(BoxTasbihCounter.salawatKey);
    await apply(
      enabled: c.reminderEnabled,
      intervalHours: c.reminderIntervalHours,
      hour: c.reminderHour,
      minute: c.reminderMinute,
      reservedTimes: reservedTimes,
    );
    return occupiedTimesToday();
  }

  /// Applies the given reminder configuration: clears any existing schedule,
  /// then (re)schedules according to [enabled] / [intervalHours].
  ///
  /// [intervalHours] of `0` selects specific-time mode ([hour]:[minute]);
  /// any positive value selects interval mode (the explicit time is ignored).
  /// Omitting [reservedTimes] reuses the set from the last coordinated run.
  Future<void> apply({
    required bool enabled,
    required int intervalHours,
    required int hour,
    required int minute,
    List<DateTime>? reservedTimes,
  }) async {
    final reserved = reservedTimes ?? _lastReserved;
    await disable();
    if (!enabled) return;

    final slots = _slotsFor(intervalHours, hour, minute, reserved);
    for (final (id, h, m) in slots) {
      await _scheduleOne(id, h, m);
    }
    AppLogger.info(
      'Salawat reminders scheduled (${slots.length} slots, every ${intervalHours}h, '
      '${reserved.length} reserved times)',
      tag: 'Salawat',
    );
  }

  /// Resolves the configuration into `(notificationId, hour, minute)` slots.
  /// Pure, and reused by [occupiedTimesToday] so the times reported to the
  /// hourly zekr always match what was actually scheduled.
  List<(int, int, int)> _slotsFor(
    int intervalHours,
    int hour,
    int minute,
    List<DateTime> reserved,
  ) {
    // Specific-time mode: the user picked the time, so it's honoured as-is —
    // including outside the window. Interval mode spreads reminders through the
    // day and needs a window to spread them across; naming an exact time is a
    // deliberate choice the window has no business overriding.
    if (intervalHours <= 0) return [(_specificId, hour, minute)];

    // Each placed slot joins the reserved set, so two salawat reminders can't
    // be pushed onto the same minute either.
    final taken = NotificationSlots.minutesOfDay(reserved);
    final slots = <(int, int, int)>[];
    for (final h in _appSettings.reminderWindow().hoursEvery(intervalHours)) {
      final m = NotificationSlots.pickMinute(
        hour: h,
        reserved: taken,
        candidates: _minuteCandidates,
      );
      slots.add((_hourBase + h, h, m));
      taken.add(h * 60 + m);
    }
    return slots;
  }

  /// Schedules the notification for one slot and, in "remind while silenced"
  /// mode on Android, the clip that goes with it.
  ///
  /// The two are separate schedules for the same minute rather than one
  /// mechanism, because no single mechanism does both: only the OS can post a
  /// notification while the app is dead, and only the app can play audio the
  /// OS's Mute mode won't drop. They are armed and cancelled together, and the
  /// notification is silent in this mode so a device that *would* have played
  /// the channel sound doesn't sound twice.
  Future<void> _scheduleOne(int id, int hour, int minute) async {
    final throughSilent = _ignoreSilentOnAndroid;
    await _notifications.scheduleDaily(
      id: id,
      hour: hour,
      minute: minute,
      title: 'الصلاة على النبي ﷺ',
      body: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      channel: throughSilent
          ? AppNotificationChannels.salawatSilent
          : AppNotificationChannels.salawat,
      iosSound: _iosSound,
      // iOS can't be made to sound through the Ring/Silent switch, but it can
      // be lifted above a Focus mode when the user asked to be reminded
      // regardless — the most the platform allows here.
      iosTimeSensitive: _appSettings.current().salawatIgnoreSilent,
      payload: const NotificationPayload(type: 'salawat'),
    );
    if (throughSilent) {
      await _sound.scheduleDaily(
        id: id,
        hour: hour,
        minute: minute,
        rawRes: _androidClip,
      );
    }
  }

  /// True when the reminder should be carried by the app-played clip.
  ///
  /// Read from the persisted setting alone — never from whether the native
  /// channel happens to be reachable — so a reschedule from a background
  /// isolate (which can't reach it) picks the same channel as the UI isolate.
  /// Otherwise the notification could quietly go back to the sounding channel
  /// while the armed clips stayed in place, and the reminder would fire twice.
  bool get _ignoreSilentOnAndroid =>
      Platform.isAndroid && _appSettings.current().salawatIgnoreSilent;

  /// Cancels every reminder this source may have scheduled — notifications and
  /// the clips armed alongside them.
  ///
  /// Sweeps the whole day rather than the current window: narrowing the window
  /// (or wrapping it past midnight) would otherwise strand reminders scheduled
  /// under the previous one, and they'd keep firing outside it forever. Ids
  /// [_hourBase]+0..23 stay clear of the hourly zekr's 5000..5023 band.
  ///
  /// The clips are cleared unconditionally, not only in "remind while silenced"
  /// mode: turning the toggle OFF has to take the already-armed ones with it,
  /// and by then the setting no longer says they exist.
  Future<void> disable() async {
    await _notifications.cancel(_specificId);
    for (var h = 0; h < 24; h++) {
      await _notifications.cancel(_hourBase + h);
    }
    await _sound.cancelAll();
  }
}
