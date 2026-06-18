import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/e_sleep_timer.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

class SAudioPlayer extends Equatable {
  const SAudioPlayer({
    this.status = PlayerStatus.idle,
    this.currentAyah,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.reciterId,
    this.options = const EPlaybackOptions(),
    this.sleepTimer = ESleepTimer.off,
    this.queue = const <ParamAyahRef>[],
    this.queueIndex,
    this.error,
  });

  final PlayerStatus status;
  final ParamAyahRef? currentAyah;
  final Duration position;
  final Duration duration;
  final String? reciterId;
  final EPlaybackOptions options;
  final ESleepTimer sleepTimer;
  final List<ParamAyahRef> queue;
  final int? queueIndex;
  final String? error;

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoadingLike =>
      status == PlayerStatus.loading || status == PlayerStatus.buffering;

  SAudioPlayer copyWith({
    PlayerStatus? status,
    ParamAyahRef? currentAyah,
    bool clearCurrentAyah = false,
    Duration? position,
    Duration? duration,
    String? reciterId,
    EPlaybackOptions? options,
    ESleepTimer? sleepTimer,
    List<ParamAyahRef>? queue,
    int? queueIndex,
    bool clearQueueIndex = false,
    String? error,
    bool clearError = false,
  }) {
    return SAudioPlayer(
      status: status ?? this.status,
      currentAyah: clearCurrentAyah ? null : (currentAyah ?? this.currentAyah),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      reciterId: reciterId ?? this.reciterId,
      options: options ?? this.options,
      sleepTimer: sleepTimer ?? this.sleepTimer,
      queue: queue ?? this.queue,
      queueIndex: clearQueueIndex ? null : (queueIndex ?? this.queueIndex),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentAyah,
    position,
    duration,
    reciterId,
    options,
    sleepTimer,
    queue,
    queueIndex,
    error,
  ];
}
