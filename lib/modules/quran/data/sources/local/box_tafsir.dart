import 'package:quran/core/utils/hive_box_base.dart';

/// Stores downloaded tafsir books as primitive `String` values.
///
/// Uses a primitive box (no [TypeAdapter]) on purpose — it sidesteps codegen and
/// survives the broken build_runner. Two kinds of keys live here:
///   • `book::<bookId>`  → the decompressed JSON blob for one book.
///   • `__downloaded__`  → JSON array of downloaded book ids (the registry).
class BoxTafsir extends HiveBoxBase<String> {
  BoxTafsir() : super('quran_tafsir');

  static const String registryKey = '__downloaded__';

  static String bookKey(String bookId) => 'book::$bookId';
}
