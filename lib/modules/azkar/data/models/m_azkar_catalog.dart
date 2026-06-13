import 'package:equatable/equatable.dart';

/// A row from `azkar_catigories.json` — pure metadata describing a category and
/// the bundled asset file its azkar live in. Items are loaded lazily from
/// [filename]; the special "other azkar" row points at the category-map file.
class MAzkarCatalog extends Equatable {
  const MAzkarCatalog({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.filename,
    required this.emoji,
  });

  /// Filename of the `other_azkar.json` map; that row opens the category browser
  /// instead of a single azkar list.
  static const otherFile = 'other_azkar.json';

  factory MAzkarCatalog.fromJson(Map<String, dynamic> json) => MAzkarCatalog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nameAr: json['arName'] as String? ?? '',
        nameEn: json['enName'] as String? ?? '',
        filename: json['filename'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '📿',
      );

  final int id;
  final String nameAr;
  final String nameEn;
  final String filename;
  final String emoji;

  /// Whether this row is the "other azkar" browser entry.
  bool get isOther => filename == otherFile;

  /// Stable category id derived from the asset filename (e.g. `morning`).
  String get slug => filename.replaceAll('.json', '');

  @override
  List<Object?> get props => [id, filename];
}
