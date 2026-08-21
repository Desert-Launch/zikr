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
  });

  @HiveField(0)
  bool hasSeenOnboarding;

  @HiveField(1)
  String? lastLanguageCode;

  @HiveField(2)
  bool hasGrantedLocation;

  /// First-run guard: true once the init_notifications.json feed (azkar +
  /// quran reminders) has been scheduled, so it isn't re-seeded on every boot.
  /// Reset by `InitNotificationsService.resetAndReschedule`.
  @HiveField(3)
  bool initNotificationsScheduled;

  /// One-time guard for the hourly tasbih default-on seed. The feature shipped
  /// off by default, so installs from before that change carry an explicit
  /// `false` on disk that the new model default can't reach — see
  /// `DSHourlyTasbih.seedDefaultIfNeeded`. Set once, so a user who later
  /// switches the reminder off is never flipped back on.
  @HiveField(4)
  bool hourlyTasbihSeeded;

  /// Start of the window (inclusive hour) in which the salawat reminder and the
  /// hourly zekr may fire. Previously the hard-coded `8` in both datasources.
  ///
  /// SCOPE: these two feeds only. Adhan, prayer times, the azkar/quran feed,
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
}
