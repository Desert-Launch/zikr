import 'package:equatable/equatable.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

enum RadioPlayerStatus { idle, loading, buffering, playing, paused, error }

class SRadioPlayer extends Equatable {
  const SRadioPlayer({
    this.current,
    this.status = RadioPlayerStatus.idle,
    this.error,
  });

  /// The station currently loaded into the player (null when idle/stopped).
  final MRadioStation? current;
  final RadioPlayerStatus status;
  final String? error;

  bool get isPlaying => status == RadioPlayerStatus.playing;
  bool get isBusy =>
      status == RadioPlayerStatus.loading ||
      status == RadioPlayerStatus.buffering;

  bool isActive(String stationId) => current?.id == stationId;

  SRadioPlayer copyWith({
    MRadioStation? current,
    RadioPlayerStatus? status,
    String? error,
    bool clearError = false,
    bool clearCurrent = false,
  }) {
    return SRadioPlayer(
      current: clearCurrent ? null : (current ?? this.current),
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [current, status, error];
}
