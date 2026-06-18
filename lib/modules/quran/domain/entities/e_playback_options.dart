import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// How the player loops while playing.
///
/// - [off]        play through to the end of the surah (then optionally the
///   next surah, per [EPlaybackOptions.autoAdvanceSurah]).
/// - [singleAyah] loop the current ayah.
/// - [range]      loop a custom from–to block (single surah in v1).
/// - [surah]      loop the whole surah.
enum RepeatMode { off, singleAyah, range, surah }

/// What happens once a finite [EPlaybackOptions.repeatCount] is exhausted.
enum EAfterRepeat { stop, continueNext }

class EPlaybackOptions extends Equatable {
  const EPlaybackOptions({
    this.repeatMode = RepeatMode.off,
    this.speed = 1.0,
    this.autoAdvance = true,
    this.autoAdvanceSurah = true,
    this.afterRepeat = EAfterRepeat.continueNext,
    this.rangeFrom,
    this.rangeTo,
    this.repeatCount = 0,
  });

  final RepeatMode repeatMode;
  final double speed;

  /// Advance to the next ayah within the current surah when one finishes.
  final bool autoAdvance;

  /// At the end of a surah (repeat off), roll into the next surah.
  final bool autoAdvanceSurah;

  /// What to do when a finite [repeatCount] is reached.
  final EAfterRepeat afterRepeat;

  final ParamAyahRef? rangeFrom;
  final ParamAyahRef? rangeTo;

  /// Number of times to repeat the active unit. `0` means infinite.
  final int repeatCount;

  EPlaybackOptions copyWith({
    RepeatMode? repeatMode,
    double? speed,
    bool? autoAdvance,
    bool? autoAdvanceSurah,
    EAfterRepeat? afterRepeat,
    ParamAyahRef? rangeFrom,
    ParamAyahRef? rangeTo,
    int? repeatCount,
  }) {
    return EPlaybackOptions(
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      autoAdvanceSurah: autoAdvanceSurah ?? this.autoAdvanceSurah,
      afterRepeat: afterRepeat ?? this.afterRepeat,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  @override
  List<Object?> get props => [
    repeatMode,
    speed,
    autoAdvance,
    autoAdvanceSurah,
    afterRepeat,
    rangeFrom,
    rangeTo,
    repeatCount,
  ];
}

extension RepeatModeX on RepeatMode {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back to a mode, defaulting to [off].
  static RepeatMode fromStorage(String? value) => RepeatMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => RepeatMode.off,
  );
}

extension EAfterRepeatX on EAfterRepeat {
  /// Stable token persisted to local storage.
  String get storageKey => name;

  /// Resolves a persisted [value] back, defaulting to [continueNext].
  static EAfterRepeat fromStorage(String? value) =>
      EAfterRepeat.values.firstWhere(
        (m) => m.name == value,
        orElse: () => EAfterRepeat.continueNext,
      );
}
