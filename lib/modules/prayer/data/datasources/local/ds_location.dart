import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.label = '',
    this.countryCode,
  });
  final double latitude;
  final double longitude;
  final String label;

  /// ISO-2 country code from reverse geocoding (e.g. 'EG'). Null when the
  /// lookup failed or returned nothing — callers fall back to a default method.
  final String? countryCode;
}

/// Wraps `geolocator` with permission + service checks. Throws on hard
/// failures (permission denied forever, services off); returns null when
/// the platform simply can't return a fresh fix in time.
class DSLocation {
  DSLocation();

  Future<LocationResult?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      throw const LocationException(
        ELocationFailure.serviceDisabled,
        'Location services are disabled',
      );
    }

    // Asking every time is the point: this is what a retry after a declined
    // prompt re-runs, and the OS shows the dialog again as long as the refusal
    // was not permanent.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        ELocationFailure.deniedForever,
        'Location permission permanently denied',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        ELocationFailure.denied,
        'Location permission not granted',
      );
    }

    // Try a fresh fix first. A cold GPS start — e.g. right after the user
    // grants the permission — can exceed the time limit, so fall back to the
    // last known fix instead of failing outright (which would leave the prayer
    // screen empty until the next refresh).
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );
    } on TimeoutException {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) return null;

    final (label, countryCode) = await _reverseGeocode(
      pos.latitude,
      pos.longitude,
    );
    return LocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      label: label,
      countryCode: countryCode,
    );
  }

  /// Shows the OS location prompt (when it can still be shown) and reports
  /// whether the permission ended up granted.
  ///
  /// Unlike [currentPosition] this never throws and never waits on a GPS fix —
  /// it exists for the onboarding "Allow" button, where the whole point is that
  /// the system dialog appears on that tap. A permanently denied or restricted
  /// permission simply returns false; the caller records the answer and moves
  /// on rather than blocking the flow.
  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system location settings, where device location can be switched
  /// back on. Returns whether the screen was opened.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens this app's own settings page — the only place a permanently denied
  /// permission can be granted again.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Best-effort reverse geocode → (city label, ISO-2 country code). Never
  /// throws: on any platform/network error returns ('', null) so prayer-time
  /// fetching still proceeds with the default calculation method.
  Future<(String, String?)> _reverseGeocode(double lat, double lon) async {
    try {
      final places = await placemarkFromCoordinates(lat, lon);
      if (places.isEmpty) return ('', null);
      final p = places.first;
      final city = p.locality?.isNotEmpty == true
          ? p.locality
          : (p.administrativeArea?.isNotEmpty == true
              ? p.administrativeArea
              : p.country);
      return (city ?? '', p.isoCountryCode);
    } catch (_) {
      return ('', null);
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.reason, this.message);

  /// What went wrong, in a form the UI can translate and act on.
  final ELocationFailure reason;

  /// Untranslated detail, for logs only — never put this on screen.
  final String message;

  @override
  String toString() => 'LocationException(${reason.name}): $message';
}
