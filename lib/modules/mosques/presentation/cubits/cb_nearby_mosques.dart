import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/mosques/domain/usecases/uc_get_nearby_mosques.dart';
import 'package:quran/modules/mosques/presentation/cubits/s_nearby_mosques.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

/// Locates the reader, then lists the mosques nearest to them.
class CBNearbyMosques extends Cubit<SNearbyMosques> {
  CBNearbyMosques({
    required DSLocation location,
    required DSLastLocation lastLocation,
    required UCGetNearbyMosques getNearby,
  })  : _location = location,
        _lastLocation = lastLocation,
        _getNearby = getNearby,
        super(const SNearbyMosques());

  final DSLocation _location;
  final DSLastLocation _lastLocation;
  final UCGetNearbyMosques _getNearby;

  /// A pull-to-refresh and a return from settings can both ask at once; one
  /// lookup at a time is enough (each one is a billed Places request).
  bool _busy = false;

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    try {
      // A list already on screen stays through a refresh; only an empty screen
      // falls back to the spinner.
      if (state.mosques.isEmpty) {
        emit(state.copyWith(
          status: NearbyMosquesStatus.loading,
          clearError: true,
        ));
      }

      final fix = await _locate();
      if (fix == null || isClosed) return;
      emit(state.copyWith(
        locationLabel: fix.label,
        latitude: fix.latitude,
        longitude: fix.longitude,
      ));

      final result = await _getNearby(
        latitude: fix.latitude,
        longitude: fix.longitude,
        languageCode: LocalizeAndTranslate.getLanguageCode(),
      );
      if (isClosed) return;
      result.fold(
        (failure) => emit(state.copyWith(
          status: NearbyMosquesStatus.failure,
          mosques: const [],
          clearError: true,
          errorKey: failure is NetworkFailure
              ? 'mosques_error_network'
              : 'mosques_error_generic',
        )),
        (mosques) => emit(state.copyWith(
          status: NearbyMosquesStatus.success,
          mosques: mosques,
          clearError: true,
          // A refresh keeps the pick only while that mosque is still listed.
          clearSelection:
              !mosques.any((m) => m.id == state.selectedMosqueId),
        )),
      );
    } finally {
      _busy = false;
    }
  }

  /// Marks [mosqueId] as the one the reader is looking at; null clears it.
  /// See [SNearbyMosques.selectedMosqueId].
  void selectMosque(String? mosqueId) {
    if (mosqueId == state.selectedMosqueId) return;
    emit(mosqueId == null
        ? state.copyWith(clearSelection: true)
        : state.copyWith(selectedMosqueId: mosqueId));
  }

  /// The recovery for [SNearbyMosques.locationFailure] that can actually work:
  /// asking again only helps while the OS will still show its dialog, so a
  /// switched-off service or a permanent refusal sends the reader to the
  /// settings page that owns it (the screen reloads when they come back).
  Future<void> recover() async {
    final failure = state.locationFailure;
    if (failure == null || !failure.needsSystemSettings) return load();
    if (failure == ELocationFailure.serviceDisabled) {
      await _location.openLocationSettings();
    } else {
      await _location.openAppSettings();
    }
  }

  /// A fresh fix, else the last one the app stored. Emits the failure and
  /// returns null when neither is available.
  Future<LocationResult?> _locate() async {
    try {
      final fix = await _location.currentPosition();
      if (fix != null) return fix;
    } on LocationException catch (e) {
      // The reader has to act here. Falling back to a cached fix would quietly
      // list mosques around wherever they were last, not where they are.
      AppLogger.warning('Nearby mosques location: $e', tag: 'CBNearbyMosques');
      if (!isClosed) {
        emit(state.copyWith(
          status: NearbyMosquesStatus.failure,
          mosques: const [],
          clearError: true,
          locationFailure: e.reason,
        ));
      }
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Nearby mosques location',
        error: e,
        stackTrace: st,
        tag: 'CBNearbyMosques',
      );
    }

    // The GPS simply had nothing in time — the last stored fix is the best
    // guess, and its city shows in the header so the reader can tell.
    final cached = _lastLocation.read();
    if (cached != null) return cached;
    if (!isClosed) {
      emit(state.copyWith(
        status: NearbyMosquesStatus.failure,
        mosques: const [],
        clearError: true,
        errorKey: 'mosques_no_location',
      ));
    }
    return null;
  }
}
