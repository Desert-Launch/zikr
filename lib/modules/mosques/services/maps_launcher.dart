import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';
import 'package:url_launcher/url_launcher.dart';

/// The map apps the nearby-mosques screen hands off to.
enum MapsApp { google, apple }

/// Builds the hand-off links into Google Maps / Apple Maps and opens them.
///
/// Every link is a plain https URL: each opens its native app when installed
/// (universal links on iOS, app links on Android) and the web map otherwise, so
/// nothing has to be declared in `LSApplicationQueriesSchemes` or `<queries>`.
class MapsLauncher {
  MapsLauncher._();

  /// Turn-by-turn directions from the reader's position to [mosque].
  static Uri directionsTo(MapsApp app, EMosque mosque) {
    final coords = '${mosque.latitude},${mosque.longitude}';
    return switch (app) {
      // The place id pins the route to the mosque itself; the coordinates are
      // the fallback Google uses if the id can't be resolved.
      MapsApp.google => Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': coords,
          if (mosque.id.isNotEmpty) 'destination_place_id': mosque.id,
        }),
      MapsApp.apple => Uri.https('maps.apple.com', '/', {'daddr': coords}),
    };
  }

  /// A map of every mosque around ([latitude], [longitude]).
  static Uri mosquesAround(MapsApp app, double latitude, double longitude) {
    return switch (app) {
      MapsApp.google => Uri.parse(
          'https://www.google.com/maps/search/mosque/@$latitude,$longitude,15z',
        ),
      MapsApp.apple => Uri.https('maps.apple.com', '/', {
          'q': 'mosque',
          'sll': '$latitude,$longitude',
          'z': '15',
        }),
    };
  }

  /// Opens [uri] outside the app. False when nothing could handle it.
  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
