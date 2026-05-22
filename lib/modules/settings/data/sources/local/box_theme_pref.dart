import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/settings/data/models/m_theme_pref.dart';

/// Single-record box (key = 0) holding the user's chosen theme mode.
class BoxThemePref extends HiveBoxBase<MThemePref> {
  BoxThemePref() : super('app_theme_pref');

  MThemePref? current() => box.get(0);

  Future<void> setMode(int modeIndex) async {
    final existing = current();
    if (existing != null) {
      existing.modeIndex = modeIndex;
      await existing.save();
    } else {
      await box.put(0, MThemePref(modeIndex: modeIndex));
    }
  }
}
