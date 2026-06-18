import 'package:quran/core/utils/hive_box_base.dart';

/// Persists audio-player preferences as primitive values (no [TypeAdapter]).
///
/// Like `BoxReaderSettings`, this uses an untyped primitive box on purpose — it
/// stores `double`/`int`/`bool`/`String` scalars under string keys and so
/// sidesteps codegen entirely (the build_runner pipeline is broken here).
///
/// Only the durable subset of `EPlaybackOptions` lives here. Transient fields
/// (range endpoints, sleep timer) are per-session and intentionally not stored.
class BoxPlaybackPrefs extends HiveBoxBase<dynamic> {
  BoxPlaybackPrefs() : super('quran_playback_prefs');

  static const String speedKey = 'speed';
  static const String repeatModeKey = 'repeat_mode';
  static const String repeatCountKey = 'repeat_count';
  static const String afterRepeatKey = 'after_repeat';
  static const String autoAdvanceSurahKey = 'auto_advance_surah';
}
