import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_adhan_settings.g.dart';

/// Adhan-notification behaviour. Single record (key = 0) in
/// `BoxAdhanSettings`. Voice selection stays in [MAdhanPreference] and the
/// per-prayer toggles stay in `MPrayerSettings.notifyForPrayer`; this model
/// only owns the cross-cutting notification preferences.
@HiveType(typeId: HiveTypeIds.adhanSettings)
class MAdhanSettings extends HiveObject {
  MAdhanSettings({
    this.enabled = true,
    this.playbackMode = 'full', // == playbackFull; literal so the Hive
    // adapter generator can inline it as a field default.
    this.androidBackgroundFullAdhan = true,
    this.preNotifyMinutes = 0,
    this.bootstrapped = false,
    this.fullScreenAlarm = true,
    this.alarmDefaultsApplied = false,
  });

  /// Notification sound is a short bundled clip (works while killed).
  static const String playbackClip = 'clip';

  /// Full adhan — plays in-app when foregrounded (and Android background when
  /// [androidBackgroundFullAdhan] is on).
  static const String playbackFull = 'full';

  /// Master switch. Off → all adhan notifications cancelled.
  @HiveField(0)
  bool enabled;

  /// `'clip'` | `'full'` — see the constants above.
  @HiveField(1)
  String playbackMode;

  /// Android-only Tier-2: auto-play the full adhan in the background.
  @HiveField(2)
  bool androidBackgroundFullAdhan;

  // Field 3 was `vibrate`. Retired: Android takes vibration from the channel
  // from API 26 on, so the flag never reached a modern device, and the adhan
  // channels are now created non-vibrating. Never reuse the index — records
  // written before this still carry a value at 3.

  /// Optional "remind me X minutes before" silent reminder. 0 = off.
  @HiveField(4)
  int preNotifyMinutes;

  /// Set once the first-launch default-voice download flow has run, so it
  /// doesn't repeat every cold start.
  @HiveField(5)
  bool bootstrapped;

  /// Raise a full-screen, over-the-lockscreen alarm at prayer time instead of a
  /// plain notification.
  ///
  /// Android: a full-screen-intent `AdhanAlarmActivity` with `showWhenLocked` +
  /// `turnScreenOn`. iOS 26+: an AlarmKit alarm (system Lock Screen UI).
  /// iOS < 26: a critical alert, which is as close as Apple allows.
  @HiveField(6)
  bool fullScreenAlarm;

  /// Migration marker for the "unmissable by default" rollout. Records created
  /// before it existed kept `playbackMode: 'clip'` and background full-adhan
  /// off; [BoxAdhanSettings.current] flips those forward exactly once and sets
  /// this, so a user who later opts back out isn't overridden again.
  @HiveField(7)
  bool alarmDefaultsApplied;
}
