import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.label = '',
  });
  final double latitude;
  final double longitude;
  final String label;
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
      throw const LocationException('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission permanently denied');
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Location permission not granted');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
      ),
    );
    return LocationResult(latitude: pos.latitude, longitude: pos.longitude);
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => 'LocationException: $message';
}
