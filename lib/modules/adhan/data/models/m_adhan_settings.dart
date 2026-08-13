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
    this.vibrate = false,
    this.adhanVolume = 100,
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

  // Field 3 was an earlier `vibrate` flag that Android never honoured (it was
  // passed per-notification, which API 26+ ignores in favour of the channel).
  // The working replacement lives at field 8 and switches channels instead.
  // Never reuse index 3 — records written before it was retired still carry a
  // value there, and re-reading it would resurrect a meaningless setting.

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

  /// Vibrate alongside the adhan alert.
  ///
  /// Android decides vibration from the notification CHANNEL (API 26+), and a
  /// channel's vibration is frozen at creation — so this flag doesn't configure
  /// a channel, it *picks* one: every adhan channel has a non-vibrating and a
  /// vibrating twin, and the scheduler routes to the matching set. The twin is
  /// only created at boot, so a flip takes visible effect from the next app
  /// start.
  ///
  /// iOS has no app-controlled equivalent — vibration there follows the system
  /// notification settings. The flag only gates the in-app ringing-screen
  /// haptic on that platform.
  ///
  /// Defaults to off: the adhan announces itself, and legacy records written
  /// while the setting didn't exist decode to this same default.
  @HiveField(8)
  bool vibrate;

  /// How loud the adhan should be, 0–100.
  ///
  /// Android: the native playback service raises the device's ALARM stream to
  /// this share of its maximum for the length of the adhan and puts it back
  /// afterwards — the only way to be louder than the user's current setting,
  /// since Android has no per-app volume. Works with the app killed because the
  /// value is baked into the scheduled alarm rather than read from Dart.
  ///
  /// iOS: scales IN-APP playback only. Apple caps the notification / AlarmKit
  /// path at the system volume and `AVAudioPlayer.volume` can only attenuate,
  /// so nothing here can make a killed-app adhan louder.
  ///
  /// Defaults to 100 — the loudest, which is what a call to prayer wants.
  @HiveField(9)
  int adhanVolume;
}
