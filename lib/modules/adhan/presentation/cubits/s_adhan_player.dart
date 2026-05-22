import 'package:equatable/equatable.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';

enum AdhanPlayerStatus { idle, loading, playing, paused, completed, error }

class SAdhanPlayer extends Equatable {
  const SAdhanPlayer({
    this.status = AdhanPlayerStatus.idle,
    this.allAdhans = const [],
    this.defaultAdhan,
    this.fajrAdhan,
    this.useFajrSpecific = true,
    this.currentPreview,
    this.error,
  });

  final AdhanPlayerStatus status;
  final List<MAdhan> allAdhans;
  final MAdhan? defaultAdhan;
  final MAdhan? fajrAdhan;
  final bool useFajrSpecific;
  final MAdhan? currentPreview;
  final String? error;

  SAdhanPlayer copyWith({
    AdhanPlayerStatus? status,
    List<MAdhan>? allAdhans,
    MAdhan? defaultAdhan,
    MAdhan? fajrAdhan,
    bool? useFajrSpecific,
    MAdhan? currentPreview,
    bool clearPreview = false,
    String? error,
    bool clearError = false,
  }) {
    return SAdhanPlayer(
      status: status ?? this.status,
      allAdhans: allAdhans ?? this.allAdhans,
      defaultAdhan: defaultAdhan ?? this.defaultAdhan,
      fajrAdhan: fajrAdhan ?? this.fajrAdhan,
      useFajrSpecific: useFajrSpecific ?? this.useFajrSpecific,
      currentPreview: clearPreview ? null : (currentPreview ?? this.currentPreview),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        allAdhans,
        defaultAdhan,
        fajrAdhan,
        useFajrSpecific,
        currentPreview,
        error,
      ];
}
