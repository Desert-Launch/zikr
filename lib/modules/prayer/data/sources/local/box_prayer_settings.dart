import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';

/// The prayer-preferences store.
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

  /// The authority Aladhan last actually used, so settings can name it in
  /// automatic mode and the offline fallback can match it.
  (int?, String?) resolvedMethod() {
    final record = current();
    return (record.resolvedMethodId, record.resolvedMethodName);
  }

  Future<void> saveResolvedMethod(int? id, String? name) async {
    if (id == null) return;
    final record = current();
    if (record.resolvedMethodId == id && record.resolvedMethodName == name) {
      return; // no write on every refresh when nothing changed
    }
    record
      ..resolvedMethodId = id
      ..resolvedMethodName = name;
    await save(record);
  }
}
