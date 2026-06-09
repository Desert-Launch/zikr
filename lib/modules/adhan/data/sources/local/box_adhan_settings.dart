import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';

class BoxAdhanSettings extends HiveBoxBase<MAdhanSettings> {
  BoxAdhanSettings() : super('adhan_settings');

  MAdhanSettings current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MAdhanSettings();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> save(MAdhanSettings settings) async {
    await box.put(0, settings);
  }
}
