import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_app_settings.g.dart';

/// App-wide settings persisted as a single Hive record (key = 0).
/// Holds first-run flags and other boot-relevant state that doesn't fit a
/// feature module's box.
@HiveType(typeId: HiveTypeIds.appSettings)
class MAppSettings extends HiveObject {
  MAppSettings({
    this.hasSeenOnboarding = false,
    this.lastLanguageCode,
    this.hasGrantedLocation = false,
    this.initNotificationsScheduled = false,
    this.hourlyTasbihSeeded = false,
    this.reminderWindowStartHour = 8,
    this.reminderWindowEndHour = 22,
    this.salawatIgnoreSilent = false,
    this.salawatPauseOnCall = true,
    this.hourlyZikrSound = true,
    this.salawatVolume = defaultReminderVolume,
    this.hourlyZikrVolume = defaultReminderVolume,
    this.hourlyWindowStartHour = 8,
    this.hourlyWindowEndHour = 22,
    this.hourlyRotationAnchorDay = 0,
  });

  /// Default for [salawatVolume] and [hourlyZikrVolume]. Gentler than the
  /// adhan's 100: these are short reminders that fire many times a day, and the
  /// level is a share of the ALARM stream's maximum, which is built to wake a
  /// sleeper.
  static const int defaultReminderVolume = 60;

  @HiveField(0)
  bool hasSeenOnboarding;

  @HiveField(1)
  String? lastLanguageCode;

  @HiveField(2)
  bool hasGrantedLocation;

  /// First-run guard: true once the init_notifications.json feed (azkar +
  /// quran reminders) has been scheduled, so it isn't re-seeded on every boot.
  @HiveField(3)
  bool initNotificationsScheduled;

  /// One-time guard for the hourly tasbih default-on seed. The feature shipped
  /// off by default, so installs from before that change carry an explicit
  /// `false` on disk that the new model default can't reach — see
  /// `DSHourlyTasbih.seedDefaultIfNeeded`. Set once, so a user who later
  /// switches the reminder off is never flipped back on.
  @HiveField(4)
  bool hourlyTasbihSeeded;

  /// Start of the window (inclusive hour) in which the salawat reminder may
  /// fire. Previously the hard-coded `8`.
  ///
  /// SCOPE: the salawat reminder only — the hourly zekr has its own range
  /// ([hourlyWindowStartHour]). Adhan, prayer times, the azkar/quran feed,
  /// khatma and user reminders ignore the window entirely — a prayer must fire
  /// at its time regardless of when the user sleeps.
  @HiveField(5)
  int reminderWindowStartHour;

  /// End of the reminder window (inclusive hour) — previously the hard-coded
  /// `22`. A value below [reminderWindowStartHour] wraps past midnight.
  @HiveField(6)
  int reminderWindowEndHour;

  /// Route the salawat reminder through an alarm-attributed channel so it
  /// sounds while the phone is on silent/vibrate.
  ///
  /// Android-only in effect. iOS cannot force sound through Silent mode without
  /// the critical-alert entitlement, which this app does not hold.
  @HiveField(7)
  bool salawatIgnoreSilent;

  /// Hold back app-played salawat audio/haptics while another app owns the
  /// audio session — a phone call, in practice. Detected via audio-focus loss
  /// (Android) / `AVAudioSession` interruption (iOS), so it needs no
  /// READ_PHONE_STATE grant. Best-effort by design.
  @HiveField(8)
  bool salawatPauseOnCall;

  /// Play each hourly zekr's own recording as the notification sound, instead
  /// of leaving the reminder on the silent `hourly_channel`.
  ///
  /// Switching this off doesn't just mute a channel — Android freezes a
  /// channel's sound at creation, so the two modes are two different sets of
  /// channels and the hourly feed has to be rescheduled onto the other set.
  /// See `DSHourlyTasbih.enable`.
  ///
  /// An hour whose clip isn't bundled falls back to the silent channel however
  /// this is set, so turning it on can't produce a notification that claims to
  /// have audio and doesn't.
  @HiveField(9)
  bool hourlyZikrSound;

  /// Salawat reminder loudness, 0–100 — the same idea as
  /// `MAdhanSettings.adhanVolume`.
  ///
  /// Android: the native clip raises (or lowers) the device's ALARM stream to
  /// this share of its maximum for the few seconds it plays, then puts it back.
  /// Baked into each armed alarm, so a change needs a reschedule. 0 mutes the
  /// clip; the notification itself still arrives.
  ///
  /// iOS: no effect. A notification sound always plays at the system volume,
  /// and the reminder never plays through the app.
  @HiveField(10)
  int salawatVolume;

  /// Hourly zekr loudness, 0–100. Same mechanism and caveats as
  /// [salawatVolume]; only meaningful while [hourlyZikrSound] is on.
  @HiveField(11)
  int hourlyZikrVolume;

  /// First hour (inclusive) of the hourly zekr's own range — one notification
  /// per hour from here to [hourlyWindowEndHour].
  ///
  /// The hourly zekr used to share the salawat window
  /// ([reminderWindowStartHour]), so a record written before this field
  /// existed decodes to that window's values: an upgrade leaves the hours the
  /// user already had untouched.
  @HiveField(12)
  int hourlyWindowStartHour;

  /// Last hour (inclusive) of the hourly zekr's range. A value below
  /// [hourlyWindowStartHour] wraps past midnight.
  @HiveField(13)
  int hourlyWindowEndHour;

  /// Day the hourly zekr rotation counts from (days since 1970-01-01, see
  /// `HourlyRotation.epochDay`) — its "day 1".
  ///
  /// Only matters when the range has fewer hours than there are azkar, so they
  /// spread over several days. Re-stamped whenever the range changes, so the
  /// first range after a change opens on the first zekr. `0` (the epoch) on
  /// records from before the rotation existed: any fixed day works, it just
  /// decides which part of the cycle today falls on.
  @HiveField(14)
  int hourlyRotationAnchorDay;
}
