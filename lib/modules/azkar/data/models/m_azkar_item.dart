import 'package:equatable/equatable.dart';

/// A single zekr from a bundled JSON file. Pure data — favorites + progress
/// live in separate Hive models keyed by [id].
class MAzkarItem extends Equatable {
  const MAzkarItem({
    required this.id,
    required this.textAr,
    required this.repeat,
    this.source,
    this.virtueAr,
  });

  /// Builds an item from the bundled schema:
  /// `{ id, count, zekr, reference, category, fadel_zeker[] }`.
  ///
  /// [categoryId] is prefixed onto the raw numeric id so item ids stay globally
  /// unique (the raw ids restart at 1 in every daily file).
  factory MAzkarItem.fromJson(Map<String, dynamic> json, String categoryId) {
    final reference = (json['reference'] as String?)?.trim();
    final virtue = (json['fadel_zeker'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .join('\n');
    return MAzkarItem(
      id: composeId(categoryId, json['id']),
      textAr: (json['zekr'] as String?)?.trim() ?? '',
      repeat: (json['count'] as num?)?.toInt() ?? 1,
      source: (reference?.isEmpty ?? true) ? null : reference,
      virtueAr: (virtue?.isEmpty ?? true) ? null : virtue,
    );
  }

  /// The single rule that turns a category slug + a raw file id into the app's
  /// globally-unique dhikr id. Lives here so the build-time audio-mapping tools
  /// (`tool/azkar_audio/`) compose ids exactly the way the app parses them —
  /// a drift between the two would silently unmap every recording.
  static String composeId(String categoryId, Object? rawId) =>
      '${categoryId}_$rawId';

  final String id;
  final String textAr;
  final int repeat;
  final String? source;
  final String? virtueAr;

  @override
  List<Object?> get props => [id];
}

/// A category (morning, evening, sleep, etc.) and its items.
class MAzkarCategory extends Equatable {
  const MAzkarCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.items,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<MAzkarItem> items;

  @override
  List<Object?> get props => [id];
}
