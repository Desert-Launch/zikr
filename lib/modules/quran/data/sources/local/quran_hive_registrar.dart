import 'package:hive_ce/hive.dart';
import 'package:quran/hive_registrar.g.dart';

/// Wraps the hive_ce_generator-produced `HiveRegistrar` extension so `main()`
/// only depends on a single, stable symbol.
class QuranHiveRegistrar {
  QuranHiveRegistrar._();

  static bool _registered = false;

  static void registerAdapters() {
    if (_registered) return;
    Hive.registerAdapters();
    _registered = true;
  }
}
