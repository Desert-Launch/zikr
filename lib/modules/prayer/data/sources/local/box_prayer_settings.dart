import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// The prayer-preferences store, and the only place the persisted
/// [MPrayerSettings] record is translated into the domain's
/// [EPrayerSettings] — so stored indices never reach a cubit or a widget.
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

  /// The calculation preferences as the domain sees them.
  ///
  /// Every read is defensive: a record written before a field existed decodes
  /// to that field's default, which is what makes the upgrade path "existing
  /// users get safe defaults" rather than "existing users get whatever bytes
  /// happened to be there".
  EPrayerSettings calculation() {
    final record = current();
    return EPrayerSettings(
      mode: ECalculationModeX.fromIndex(record.calculationModeIndex),
      manualMethodId: record.manualMethodId,
      asrSchool: EAsrSchoolX.fromIndex(record.madhabIndex),
      highLatitudeRule: EHighLatitudeRuleX.fromIndex(
        record.highLatitudeRuleIndex,
      ),
      adjustments: EPrayerAdjustments.fromList(record.tuneMinutes),
    );
  }

  Future<void> saveCalculation(EPrayerSettings settings) async {
    final record = current();
    record
      ..calculationModeIndex = settings.mode.index
      ..manualMethodId = settings.manualMethodId
      ..madhabIndex = settings.asrSchool.storageIndex
      ..highLatitudeRuleIndex = settings.highLatitudeRule.index
      // Nine zeroes are the default; storing null keeps the record identical
      // to one written before the setting existed.
      ..tuneMinutes = settings.adjustments.isZero
          ? null
          : settings.adjustments.toList();
    await save(record);
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
