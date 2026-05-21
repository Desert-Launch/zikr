import 'package:quran/modules/quran/data/models/m_reciter_pref.dart';
import 'package:quran/modules/quran/data/sources/local/box_reciter_pref.dart';

/// Persists module-level settings (active reciter, default-reciter pinning).
class DSLocalSettings {
  DSLocalSettings(this._box);
  final BoxReciterPref _box;

  Future<void> init() => _box.init();

  String? getActiveReciterId() => _box.box.get(BoxReciterPref.singletonKey)?.activeReciterId;

  Future<void> setActiveReciterId(String id) async {
    await _box.box.put(
      BoxReciterPref.singletonKey,
      MReciterPref(activeReciterId: id, lastChangedAt: DateTime.now()),
    );
  }
}
