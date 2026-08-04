import 'package:equatable/equatable.dart';

/// State for the in-app full-screen adhan alarm.
class SAdhanRinging extends Equatable {
  const SAdhanRinging({
    this.prayerKey = 'fajr',
    this.voiceNameAr = '',
    this.playing = false,
    this.stopped = false,
    this.startedAt,
  });

  /// fajr / dhuhr / asr / maghrib / isha.
  final String prayerKey;

  /// Reciter name for the currently playing adhan; empty until resolved.
  final String voiceNameAr;

  /// True while the adhan audio is actually playing.
  final bool playing;

  /// True once the user stopped it (or playback completed), so the screen can
  /// dismiss itself.
  final bool stopped;

  /// Wall-clock time the alarm was raised — the time shown on screen. Held in
  /// state rather than read at build time so a rebuild can't shift it.
  final DateTime? startedAt;

  SAdhanRinging copyWith({
    String? prayerKey,
    String? voiceNameAr,
    bool? playing,
    bool? stopped,
    DateTime? startedAt,
  }) {
    return SAdhanRinging(
      prayerKey: prayerKey ?? this.prayerKey,
      voiceNameAr: voiceNameAr ?? this.voiceNameAr,
      playing: playing ?? this.playing,
      stopped: stopped ?? this.stopped,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [
    prayerKey,
    voiceNameAr,
    playing,
    stopped,
    startedAt,
  ];
}
