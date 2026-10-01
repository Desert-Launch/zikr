import 'package:equatable/equatable.dart';

/// A mosque near the reader, as shown on the nearby-mosques list.
class EMosque extends Equatable {
  const EMosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  /// Google place id. Passed to Google Maps so directions land on the place
  /// itself rather than on a bare coordinate.
  final String id;
  final String name;

  /// Short street/area address. May be empty when Google has none.
  final String address;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the search centre (the reader's location).
  final double distanceMeters;

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, distanceMeters];
}
