import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/data/sources/local/box_radio_favorite.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_live_stations.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_national_stations.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio.dart';

/// Loads the radio station lists for [SNRadio]: the curated national broadcasts
/// first (instant, offline-safe), then the live mp3quran catalogue (best-effort).
class CBRadio extends Cubit<SRadio> {
  CBRadio({
    required UCGetNationalStations getNational,
    required UCGetLiveStations getLive,
    required BoxRadioFavorite favorites,
  }) : _getNational = getNational,
       _getLive = getLive,
       _favorites = favorites,
       super(const SRadio());

  final UCGetNationalStations _getNational;
  final UCGetLiveStations _getLive;
  final BoxRadioFavorite _favorites;

  Future<void> load({String language = 'ar'}) async {
    emit(
      state.copyWith(
        status: RadioStatus.loading,
        favoriteIds: _favorites.ids(),
        clearError: true,
      ),
    );

    final nationalRes = await _getNational();
    nationalRes.fold(
      (failure) => emit(
        state.copyWith(status: RadioStatus.error, error: failure.message),
      ),
      (stations) => emit(
        state.copyWith(
          status: RadioStatus.ready,
          national: stations,
          liveLoading: true,
        ),
      ),
    );

    if (state.status == RadioStatus.error) return;
    await _loadLive(language);
  }

  /// Filters both station sections by name as the user types.
  void setQuery(String query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
  }

  /// Favorites/unfavorites a station. Favorited stations are pinned to the top
  /// of the "more stations" section (see [SRadio.visibleLive]).
  Future<void> toggleFavorite(MRadioStation station) async {
    await _favorites.toggle(station.id, name: station.name);
    emit(state.copyWith(favoriteIds: _favorites.ids()));
  }

  /// Re-runs only the live (network) section — used by pull-to-refresh / retry.
  Future<void> refreshLive({String language = 'ar'}) async {
    if (state.liveLoading) return;
    emit(state.copyWith(liveLoading: true));
    await _loadLive(language);
  }

  Future<void> _loadLive(String language) async {
    final liveRes = await _getLive(language: language);
    liveRes.fold(
      (_) => emit(state.copyWith(liveLoading: false)),
      (stations) => emit(state.copyWith(live: stations, liveLoading: false)),
    );
  }
}
