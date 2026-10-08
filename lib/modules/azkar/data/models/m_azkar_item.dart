import 'package:equatable/equatable.dart';

/// A single zekr from a bundled JSON file. Pure data — favorites + progress
/// live in separate Hive models keyed by [id].
class MAzkarItem extends Equatable {
  const MAzkarItem({
    required this.id,
    required this.textAr,
    required this.repeat,
    this.textEn,
    this.virtueAr,
    this.virtueEn,
    this.audioAsset,
    this.isClosing = false,
  });

  /// Builds an item from the bundled schema (written by
  /// `tool/import_azkar_sheet.py`):
  /// `{ id, sort, count, zekr, zekr_en, reference, fadel_zeker[], audio,
  /// closing }`.
  ///
  /// `zekr` + `fadel_zeker` are the Arabic text and virtue; `zekr_en` (the
  /// Arabic plus a transliteration and a translation) + `reference` are their
  /// English counterparts. Older files carry only the Arabic pair, and no
  /// `closing`.
  ///
  /// [categoryId] is prefixed onto the raw numeric id so item ids stay globally
  /// unique (the raw ids restart at 1 in every daily file).
  factory MAzkarItem.fromJson(Map<String, dynamic> json, String categoryId) {
    final virtue = (json['fadel_zeker'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .join('\n');
    return MAzkarItem(
      id: '${categoryId}_${json['id']}',
      textAr: (json['zekr'] as String?)?.trim() ?? '',
      textEn: _text(json['zekr_en']),
      repeat: (json['count'] as num?)?.toInt() ?? 1,
      virtueAr: (virtue?.isEmpty ?? true) ? null : virtue,
      virtueEn: _text(json['reference']),
      audioAsset: _audioAsset(json['audio']),
      isClosing: json['closing'] == true,
    );
  }

  static const _audioDir = 'assets/audio/zike-audios';

  static String? _text(Object? raw) {
    final text = raw is String ? raw.trim() : null;
    return (text?.isEmpty ?? true) ? null : text;
  }

  /// Resolves the sheet's `Audio` name to its bundled clip: `Zikr-S-1` lives at
  /// `assets/audio/zike-audios/Zikr-S/Zikr-S-1.mp3` — one folder per category,
  /// named by everything before the trailing number.
  static String? _audioAsset(Object? raw) {
    final name = _text(raw);
    if (name == null) return null;
    final cut = name.lastIndexOf('-');
    if (cut <= 0) return null;
    return '$_audioDir/${name.substring(0, cut)}/$name.mp3';
  }

  final String id;
  final String textAr;
  final String? textEn;
  final int repeat;
  final String? virtueAr;
  final String? virtueEn;

  /// Bundled recitation of this zekr, or `null` when it has none.
  final String? audioAsset;

  bool get hasAudio => audioAsset != null;

  /// The "اكتمل" card a daily list ends on — a closing message, not a zekr.
  /// It has nothing to count: no counter, and it never takes part in the
  /// day's progress (see [MAzkarCategory.countedItems]).
  final bool isClosing;

  /// The zekr body for the UI language, falling back to the Arabic.
  String text(String languageCode) =>
      languageCode == 'ar' ? textAr : (textEn ?? textAr);

  /// The virtue / reference for the UI language, falling back to the Arabic.
  String? virtue(String languageCode) =>
      languageCode == 'ar' ? virtueAr : (virtueEn ?? virtueAr);

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

  /// The azkar that are counted — every item but the closing card. What
  /// "done today" and "finished" are measured against.
  Iterable<MAzkarItem> get countedItems => items.where((item) => !item.isClosing);

  @override
  List<Object?> get props => [id];
}
