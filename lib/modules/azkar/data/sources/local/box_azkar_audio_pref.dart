import 'package:quran/core/utils/hive_box_base.dart';

/// The user's adhkar-audio preferences.
///
/// A plain `String` box (like `quran_reader_settings`) rather than a model —
/// there is one setting today and adding another must not need a Hive
/// migration.
class BoxAzkarAudioPref extends HiveBoxBase<String> {
  BoxAzkarAudioPref() : super(boxName_);

  static const String boxName_ = 'azkar_audio_prefs';

  static const String _preferredReaderKey = 'preferred_reader';

  /// Reader chosen in settings, or null while the user has not chosen one —
  /// the resolver then falls through to the first reader that has the dhikr.
  String? get preferredReaderId {
    final value = box.get(_preferredReaderKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setPreferredReaderId(String? readerId) async {
    if (readerId == null || readerId.isEmpty) {
      await box.delete(_preferredReaderKey);
      return;
    }
    await box.put(_preferredReaderKey, readerId);
  }
}
