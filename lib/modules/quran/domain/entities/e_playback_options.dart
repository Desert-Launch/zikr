import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

enum RepeatMode { off, singleAyah, range }

class EPlaybackOptions extends Equatable {
  const EPlaybackOptions({
    this.repeatMode = RepeatMode.off,
    this.speed = 1.0,
    this.autoAdvance = true,
    this.rangeFrom,
    this.rangeTo,
    this.repeatCount = 1,
  });

  final RepeatMode repeatMode;
  final double speed;
  final bool autoAdvance;
  final ParamAyahRef? rangeFrom;
  final ParamAyahRef? rangeTo;
  final int repeatCount;

  EPlaybackOptions copyWith({
    RepeatMode? repeatMode,
    double? speed,
    bool? autoAdvance,
    ParamAyahRef? rangeFrom,
    ParamAyahRef? rangeTo,
    int? repeatCount,
  }) {
    return EPlaybackOptions(
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  @override
  List<Object?> get props => [repeatMode, speed, autoAdvance, rangeFrom, rangeTo, repeatCount];
}
