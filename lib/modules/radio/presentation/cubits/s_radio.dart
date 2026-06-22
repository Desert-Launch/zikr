import 'package:equatable/equatable.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

enum RadioStatus { initial, loading, ready, error }

class SRadio extends Equatable {
  const SRadio({
    this.status = RadioStatus.initial,
    this.national = const [],
    this.live = const [],
    this.liveLoading = false,
    this.error,
  });

  /// Status of the national (curated) list — drives the main screen state.
  final RadioStatus status;
  final List<MRadioStation> national;

  /// Live mp3quran list (secondary section). Best-effort: stays empty on failure.
  final List<MRadioStation> live;
  final bool liveLoading;
  final String? error;

  SRadio copyWith({
    RadioStatus? status,
    List<MRadioStation>? national,
    List<MRadioStation>? live,
    bool? liveLoading,
    String? error,
    bool clearError = false,
  }) {
    return SRadio(
      status: status ?? this.status,
      national: national ?? this.national,
      live: live ?? this.live,
      liveLoading: liveLoading ?? this.liveLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, national, live, liveLoading, error];
}
