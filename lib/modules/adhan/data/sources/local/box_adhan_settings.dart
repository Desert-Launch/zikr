import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';

class BoxAdhanSettings extends HiveBoxBase<MAdhanSettings> {
  BoxAdhanSettings() : super('adhan_settings');

  MAdhanSettings current() {
    final existing = box.get(0);
    if (existing == null) {
      // Fresh install: the constructor defaults are already the unmissable
      // ones, so just mark the migration done and persist.
      final fresh = MAdhanSettings()..alarmDefaultsApplied = true;
      box.put(0, fresh);
      return fresh;
    }
    return _applyAlarmDefaults(existing);
  }

  /// One-time forward migration for the "unmissable by default" rollout.
  ///
  /// Records written before [MAdhanSettings.fullScreenAlarm] existed decode
  /// with the NEW field defaults for the missing bytes, but keep their own
  /// persisted `playbackMode: 'clip'` / `androidBackgroundFullAdhan: false`.
  /// Flip those forward exactly once — [MAdhanSettings.alarmDefaultsApplied]
  /// then guarantees a user who deliberately opts back out stays opted out.
  MAdhanSettings _applyAlarmDefaults(MAdhanSettings settings) {
    if (settings.alarmDefaultsApplied) return settings;
    settings
      ..playbackMode = MAdhanSettings.playbackFull
      ..androidBackgroundFullAdhan = true
      ..fullScreenAlarm = true
      ..alarmDefaultsApplied = true;
    box.put(0, settings);
    return settings;
  }

  Future<void> save(MAdhanSettings settings) async {
    await box.put(0, settings);
  }
}
