import 'package:equatable/equatable.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

/// loading → finding the reader and asking Google for mosques around them.
/// success → [SNearbyMosques.mosques] holds the result (possibly empty).
/// failure → either [SNearbyMosques.locationFailure] or
///           [SNearbyMosques.errorKey] says what went wrong.
enum NearbyMosquesStatus { loading, success, failure }

class SNearbyMosques extends Equatable {
  const SNearbyMosques({
    this.status = NearbyMosquesStatus.loading,
    this.mosques = const [],
    this.locationLabel = '',
    this.latitude,
    this.longitude,
    this.locationFailure,
    this.errorKey,
    this.selectedMosqueId,
    this.mapsReady = false,
  });

  final NearbyMosquesStatus status;

  /// Nearest first.
  final List<EMosque> mosques;

  /// City name of the fix the list was built from, for the header. Empty when
  /// reverse geocoding had nothing.
  final String locationLabel;

  /// The fix the list was built from. Null until one is obtained.
  final double? latitude;
  final double? longitude;

  /// Set when no fix could be had because of the permission or the location
  /// service — the cases the reader has to act on themselves.
  final ELocationFailure? locationFailure;

  /// i18n key for any other failure (no fix in time, network, Google error).
  final String? errorKey;

  /// [EMosque.id] of the mosque the reader picked on the map or the list, so
  /// its pin and its card light up together. Null when none is.
  final String? selectedMosqueId;

  /// Whether the native Maps SDK has its key, so the map may be built. Until
  /// then the header keeps its photo — a map without a key crashes the app.
  final bool mapsReady;

  bool get hasLocation => latitude != null && longitude != null;

  /// [clearError] drops both error fields; pass the new one alongside it to
  /// replace whichever was set before. [clearSelection] drops
  /// [selectedMosqueId].
  SNearbyMosques copyWith({
    NearbyMosquesStatus? status,
    List<EMosque>? mosques,
    String? locationLabel,
    double? latitude,
    double? longitude,
    ELocationFailure? locationFailure,
    String? errorKey,
    String? selectedMosqueId,
    bool? mapsReady,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return SNearbyMosques(
      status: status ?? this.status,
      mosques: mosques ?? this.mosques,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationFailure:
          locationFailure ?? (clearError ? null : this.locationFailure),
      errorKey: errorKey ?? (clearError ? null : this.errorKey),
      selectedMosqueId: selectedMosqueId ??
          (clearSelection ? null : this.selectedMosqueId),
      mapsReady: mapsReady ?? this.mapsReady,
    );
  }

  @override
  List<Object?> get props => [
        status,
        mosques,
        locationLabel,
        latitude,
        longitude,
        locationFailure,
        errorKey,
        selectedMosqueId,
        mapsReady,
      ];
}
