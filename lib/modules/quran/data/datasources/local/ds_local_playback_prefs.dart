import 'package:quran/modules/quran/data/sources/local/box_playback_prefs.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';

/// Reads/writes audio-player preferences from the local primitive box.
///
/// Reads fall back to the [EPlaybackOptions] defaults for any key that is
/// missing or has an unexpected type, so a fresh install or a partially-written
/// box never throws.
class DSLocalPlaybackPrefs {
  DSLocalPlaybackPrefs(this._box);
  final BoxPlaybackPrefs _box;

  Future<void> init() => _box.init();

  EPlaybackOptions getOptions() {
    final box = _box.box;
    final speed = box.get(BoxPlaybackPrefs.speedKey);
    final repeatMode = box.get(BoxPlaybackPrefs.repeatModeKey);
    final repeatCount = box.get(BoxPlaybackPrefs.repeatCountKey);
    final afterRepeat = box.get(BoxPlaybackPrefs.afterRepeatKey);
    final autoAdvanceSurah = box.get(BoxPlaybackPrefs.autoAdvanceSurahKey);

    // copyWith keeps the default for any argument passed as null, so unknown
    // or wrongly-typed stored values gracefully degrade to defaults.
    const defaults = EPlaybackOptions();
    return defaults.copyWith(
      speed: speed is num ? speed.toDouble() : null,
      repeatMode: repeatMode is String
          ? RepeatModeX.fromStorage(repeatMode)
          : null,
      repeatCount: repeatCount is int ? repeatCount : null,
      afterRepeat: afterRepeat is String
          ? EAfterRepeatX.fromStorage(afterRepeat)
          : null,
      autoAdvanceSurah: autoAdvanceSurah is bool ? autoAdvanceSurah : null,
    );
  }

  Future<void> setOptions(EPlaybackOptions options) {
    return _box.box.putAll(<String, dynamic>{
      BoxPlaybackPrefs.speedKey: options.speed,
      BoxPlaybackPrefs.repeatModeKey: options.repeatMode.storageKey,
      BoxPlaybackPrefs.repeatCountKey: options.repeatCount,
      BoxPlaybackPrefs.afterRepeatKey: options.afterRepeat.storageKey,
      BoxPlaybackPrefs.autoAdvanceSurahKey: options.autoAdvanceSurah,
    });
  }
}
