import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_live_stations.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_national_stations.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio.dart';

/// Loads the radio station lists for [SNRadio]: the curated national broadcasts
/// first (instant, offline-safe), then the live mp3quran catalogue (best-effort).
class CBRadio extends Cubit<SRadio> {
  CBRadio({
    required UCGetNationalStations getNational,
    required UCGetLiveStations getLive,
  })  : _getNational = getNational,
        _getLive = getLive,
        super(const SRadio());

  final UCGetNationalStations _getNational;
  final UCGetLiveStations _getLive;

  Future<void> load({String language = 'ar'}) async {
    emit(state.copyWith(status: RadioStatus.loading, clearError: true));

    final nationalRes = await _getNational();
    nationalRes.fold(
      (failure) =>
          emit(state.copyWith(status: RadioStatus.error, error: failure.message)),
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
