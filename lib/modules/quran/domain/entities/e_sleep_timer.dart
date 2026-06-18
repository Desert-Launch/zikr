/// Sleep-timer options for the audio player.
///
/// The timed options ([min5]–[min60]) stop after a fixed countdown with a gentle
/// fade-out. The boundary options ([endOfAyah]/[endOfSurah]) instead stop at the
/// next natural playback boundary and take precedence over an active repeat.
enum ESleepTimer {
  off,
  min5,
  min10,
  min15,
  min30,
  min60,
  endOfAyah,
  endOfSurah,
}

extension ESleepTimerX on ESleepTimer {
  /// Countdown for the timed options; null for [off] and the boundary modes.
  Duration? get duration => switch (this) {
    ESleepTimer.min5 => const Duration(minutes: 5),
    ESleepTimer.min10 => const Duration(minutes: 10),
    ESleepTimer.min15 => const Duration(minutes: 15),
    ESleepTimer.min30 => const Duration(minutes: 30),
    ESleepTimer.min60 => const Duration(minutes: 60),
    _ => null,
  };

  /// Stops at a playback boundary (end of ayah / surah) rather than a countdown.
  bool get isBoundary =>
      this == ESleepTimer.endOfAyah || this == ESleepTimer.endOfSurah;
}
