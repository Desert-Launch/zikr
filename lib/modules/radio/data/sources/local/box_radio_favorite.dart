import 'package:quran/core/utils/hive_box_base.dart';

/// Favorited radio stations from the "more stations" section, keyed by station
/// id with the station name stored as the value. Plain [String] storage — no
/// Hive adapter needed, mirroring [BoxAzkarCategoryFavorite].
class BoxRadioFavorite extends HiveBoxBase<String> {
  BoxRadioFavorite() : super('radio_favorites');

  /// Ids of every favorited station, for a cheap membership test while
  /// building the list.
  Set<String> ids() => box.keys.map((k) => k.toString()).toSet();

  bool isFavorite(String stationId) => box.containsKey(stationId);

  Future<void> toggle(String stationId, {required String name}) async {
    if (isFavorite(stationId)) {
      await box.delete(stationId);
    } else {
      await box.put(stationId, name);
    }
  }
}
