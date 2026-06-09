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
    this.playbackMode = 'clip', // == playbackClip; literal so the Hive
    // adapter generator can inline it as a field default.
    this.androidBackgroundFullAdhan = false,
    this.vibrate = true,
    this.preNotifyMinutes = 0,
    this.bootstrapped = false,
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

  @HiveField(3)
  bool vibrate;

  /// Optional "remind me X minutes before" silent reminder. 0 = off.
  @HiveField(4)
  int preNotifyMinutes;

  /// Set once the first-launch default-voice download flow has run, so it
  /// doesn't repeat every cold start.
  @HiveField(5)
  bool bootstrapped;
}
