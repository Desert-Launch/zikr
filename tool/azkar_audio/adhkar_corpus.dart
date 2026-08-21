import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quran/modules/azkar/data/models/m_azkar_catalog.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/domain/services/azkar_audio_matcher.dart';
import 'package:quran/modules/azkar/domain/services/azkar_source_text_cleaner.dart';

/// Reads the app's bundled adhkar straight off disk.
///
/// The runtime loader (`DSLocalAzkar`) goes through `rootBundle`, which needs a
/// Flutter engine; these are plain `dart run` scripts, so they read the same
/// asset files with `dart:io`. Ids are composed with [MAzkarItem.composeId] —
/// the exact rule the app parses — so the mapping files line up.
class AdhkarCorpus {
  const AdhkarCorpus._(this.targets, this.categoryNames);

  final List<AzkarMatchTarget> targets;

  /// Category id → Arabic display name.
  final Map<String, String> categoryNames;

  static const String assetDir = 'assets/data/azkar';
  static const String otherPrefix = 'other_';

  /// The app's own corpus carries the same book apparatus the external sources
  /// do — `(( ))` around the dhikr, a trailing `ثلاث مرات`, a bracketed
  /// variant. Matching compares *what is recited*, so both sides are cleaned
  /// the same way. This never touches `assets/data/azkar/`: the app keeps
  /// rendering its text exactly as authored.
  static const AzkarSourceTextCleaner _cleaner = AzkarSourceTextCleaner();

  static Future<AdhkarCorpus> load({String root = '.'}) async {
    final dir = p.join(root, assetDir);
    final catalogRaw = await File(
      p.join(dir, 'azkar_catigories.json'),
    ).readAsString();
    final catalog = (jsonDecode(catalogRaw) as List<dynamic>)
        .map((e) => MAzkarCatalog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    final targets = <AzkarMatchTarget>[];
    final names = <String, String>{};

    for (final row in catalog.where((e) => !e.isOther)) {
      names[row.slug] = row.nameAr;
      final raw = await File(p.join(dir, row.filename)).readAsString();
      for (final e in jsonDecode(raw) as List<dynamic>) {
        final map = Map<String, dynamic>.from(e as Map);
        targets.add(
          AzkarMatchTarget(
            adhkarId: MAzkarItem.composeId(row.slug, map['id']),
            categoryId: row.slug,
            categoryName: row.nameAr,
            text: _cleaner.clean(map['zekr'] as String?),
          ),
        );
      }
    }

    final otherRaw = await File(
      p.join(dir, MAzkarCatalog.otherFile),
    ).readAsString();
    final other = Map<String, dynamic>.from(jsonDecode(otherRaw) as Map);
    var index = 0;
    for (final entry in other.entries) {
      final categoryId = '$otherPrefix$index';
      names[categoryId] = entry.key;
      for (final e in entry.value as List<dynamic>) {
        final map = Map<String, dynamic>.from(e as Map);
        targets.add(
          AzkarMatchTarget(
            adhkarId: MAzkarItem.composeId(categoryId, map['id']),
            categoryId: categoryId,
            categoryName: entry.key,
            text: _cleaner.clean(map['zekr'] as String?),
          ),
        );
      }
      index++;
    }

    return AdhkarCorpus._(
      List<AzkarMatchTarget>.unmodifiable(targets),
      Map<String, String>.unmodifiable(names),
    );
  }

  /// Category id for a given dhikr id, or null when the id is unknown.
  String? categoryOf(String adhkarId) {
    for (final t in targets) {
      if (t.adhkarId == adhkarId) return t.categoryId;
    }
    return null;
  }
}
