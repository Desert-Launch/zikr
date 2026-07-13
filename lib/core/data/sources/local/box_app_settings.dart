import 'package:quran/core/data/models/m_app_settings.dart';
import 'package:quran/core/utils/hive_box_base.dart';

/// Single-record box (key = 0) for global flags like `hasSeenOnboarding`.
class BoxAppSettings extends HiveBoxBase<MAppSettings> {
  BoxAppSettings() : super('app_settings');

  MAppSettings current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MAppSettings();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final r = current();
    r.hasSeenOnboarding = value;
    await r.save();
  }

  Future<void> setLanguageCode(String? code) async {
    final r = current();
    r.lastLanguageCode = code;
    await r.save();
  }

  Future<void> setHasGrantedLocation(bool value) async {
    final r = current();
    r.hasGrantedLocation = value;
    await r.save();
  }

  Future<void> setInitNotificationsScheduled(bool value) async {
    final r = current();
    r.initNotificationsScheduled = value;
    await r.save();
  }
}
