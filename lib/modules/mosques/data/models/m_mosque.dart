import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';

/// One `places[]` entry of a Places API (New) `searchNearby` response, trimmed
/// to the fields requested in `DSRemoteMosques`'s field mask.
class MMosque {
  const MMosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// A leading Open Location Code ("8C7R+VX8, ") that Google puts in front of
  /// addresses it has no street for. Meaningless to a reader, so it is dropped
  /// and only the area that follows it is kept.
  static final RegExp _plusCode = RegExp(
    r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]*[,،]?\s*',
  );

  /// Parses one place, or returns null when it lacks a name or a location —
  /// a row that can't be labelled or navigated to is no use on the list.
  static MMosque? tryParse(Map<String, dynamic> json) {
    final name = (json['displayName'] as Map<String, dynamic>?)?['text'] as String?;
    final location = json['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    if (name == null || name.trim().isEmpty || lat == null || lng == null) {
      return null;
    }
    final rawAddress = json['shortFormattedAddress'] as String? ?? '';
    return MMosque(
      id: json['id'] as String? ?? '',
      name: name.trim(),
      address: rawAddress.replaceFirst(_plusCode, '').trim(),
      latitude: lat,
      longitude: lng,
    );
  }

  EMosque toEntity({required double distanceMeters}) => EMosque(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: distanceMeters,
      );
}
