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

  bool get hasLocation => latitude != null && longitude != null;

  /// [clearError] drops both error fields; pass the new one alongside it to
  /// replace whichever was set before.
  SNearbyMosques copyWith({
    NearbyMosquesStatus? status,
    List<EMosque>? mosques,
    String? locationLabel,
    double? latitude,
    double? longitude,
    ELocationFailure? locationFailure,
    String? errorKey,
    bool clearError = false,
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
      ];
}
