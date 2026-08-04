import 'package:equatable/equatable.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

enum RadioStatus { initial, loading, ready, error }

class SRadio extends Equatable {
  const SRadio({
    this.status = RadioStatus.initial,
    this.national = const [],
    this.live = const [],
    this.liveLoading = false,
    this.query = '',
    this.error,
  });

  /// Status of the national (curated) list — drives the main screen state.
  final RadioStatus status;
  final List<MRadioStation> national;

  /// Live mp3quran list (secondary section). Best-effort: stays empty on failure.
  final List<MRadioStation> live;
  final bool liveLoading;

  /// Live station-name filter typed into the search bar.
  final String query;
  final String? error;

  /// National stations matching [query].
  List<MRadioStation> get visibleNational => _filter(national);

  /// Live stations matching [query].
  List<MRadioStation> get visibleLive => _filter(live);

  /// Whether a query is active but nothing in either list matches.
  bool get noMatches =>
      query.trim().isNotEmpty && visibleNational.isEmpty && visibleLive.isEmpty;

  List<MRadioStation> _filter(List<MRadioStation> stations) {
    final needle = _normalise(query);
    if (needle.isEmpty) return stations;
    return stations
        .where((s) => _normalise(s.name).contains(needle))
        .toList(growable: false);
  }

  /// Folds Arabic diacritics and letter variants so a query matches the way a
  /// reader expects (e.g. "اذاعه" finds "إذاعة").
  static String _normalise(String value) => value
      .trim()
      .replaceAll(RegExp('[ً-ْٰ]'), '')
      .replaceAll(RegExp('[آأإ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .toLowerCase();

  SRadio copyWith({
    RadioStatus? status,
    List<MRadioStation>? national,
    List<MRadioStation>? live,
    bool? liveLoading,
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return SRadio(
      status: status ?? this.status,
      national: national ?? this.national,
      live: live ?? this.live,
      liveLoading: liveLoading ?? this.liveLoading,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    national,
    live,
    liveLoading,
    query,
    error,
  ];
}
