import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';

class BoxPrayerSettings extends HiveBoxBase<MPrayerSettings> {
  BoxPrayerSettings() : super('prayer_settings');

  MPrayerSettings current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MPrayerSettings();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> save(MPrayerSettings settings) async {
    await box.put(0, settings);
  }
}
