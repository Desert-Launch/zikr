import 'package:equatable/equatable.dart';

/// What a spoken or typed car query resolved to, best first.
sealed class ECarQueryMatch extends Equatable {
  const ECarQueryMatch();
}

/// A surah, optionally in a named reciter's voice (null → the active reciter).
final class ECarSurahMatch extends ECarQueryMatch {
  const ECarSurahMatch({required this.surah, this.reciterId});

  final int surah;
  final String? reciterId;

  @override
  List<Object?> get props => [surah, reciterId];
}

/// A reciter named on their own ("play Alafasy").
final class ECarReciterMatch extends ECarQueryMatch {
  const ECarReciterMatch(this.reciterId);

  final String reciterId;

  @override
  List<Object?> get props => [reciterId];
}

/// A radio station.
final class ECarStationMatch extends ECarQueryMatch {
  const ECarStationMatch(this.stationId);

  final String stationId;

  @override
  List<Object?> get props => [stationId];
}
