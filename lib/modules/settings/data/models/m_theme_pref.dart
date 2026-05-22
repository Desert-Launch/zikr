import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_theme_pref.g.dart';

/// Persisted theme preference. Single record (key = 0) per box.
@HiveType(typeId: HiveTypeIds.themePref)
class MThemePref extends HiveObject {
  MThemePref({required this.modeIndex});

  /// Index of [EThemeMode] enum value: 0=system, 1=light, 2=dark.
  @HiveField(0)
  int modeIndex;
}
