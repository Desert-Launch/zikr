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

  factory MAzkarItem.fromJson(Map<String, dynamic> json) => MAzkarItem(
        id: json['id'] as String,
        textAr: json['text_ar'] as String? ?? '',
        repeat: (json['repeat'] as int?) ?? 1,
        source: json['source'] as String?,
        virtueAr: json['virtue_ar'] as String?,
      );

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

  factory MAzkarCategory.fromJson(Map<String, dynamic> json) => MAzkarCategory(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        items: (json['items'] as List<dynamic>)
            .map((e) => MAzkarItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );

  final String id;
  final String nameAr;
  final String nameEn;
  final List<MAzkarItem> items;

  @override
  List<Object?> get props => [id];
}
