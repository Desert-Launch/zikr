import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_cache.dart';

class BoxPrayerCache extends HiveBoxBase<MPrayerCache> {
  BoxPrayerCache() : super('prayer_cache');

  MPrayerCache? current() => box.get(0);

  Future<void> save(MPrayerCache cache) async {
    await box.put(0, cache);
  }
}
