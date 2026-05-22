import 'package:equatable/equatable.dart';

/// One bundled adhan entry, loaded from `assets/data/adhans.json`. Pure
/// metadata — the actual audio lives at [asset], a bundled MP3.
class MAdhan extends Equatable {
  const MAdhan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.muezzinAr,
    required this.muezzinEn,
    required this.style,
    required this.asset,
    required this.isFajrDefault,
    required this.durationSeconds,
    this.defaultForLocales = const [],
    this.noteAr,
    this.noteEn,
  });

  factory MAdhan.fromJson(Map<String, dynamic> json) => MAdhan(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        muezzinAr: json['muezzin_ar'] as String? ?? '',
        muezzinEn: json['muezzin_en'] as String? ?? '',
        style: json['style'] as String? ?? 'modern',
        asset: json['asset'] as String? ?? '',
        isFajrDefault: json['is_fajr_default'] as bool? ?? false,
        durationSeconds: json['duration_seconds'] as int? ?? 0,
        defaultForLocales:
            (json['default_for_locales'] as List<dynamic>?)?.cast<String>() ?? const [],
        noteAr: json['note_ar'] as String?,
        noteEn: json['note_en'] as String?,
      );

  final String id;
  final String nameAr;
  final String nameEn;
  final String muezzinAr;
  final String muezzinEn;
  final String style;
  final String asset;
  final bool isFajrDefault;
  final int durationSeconds;
  final List<String> defaultForLocales;
  final String? noteAr;
  final String? noteEn;

  @override
  List<Object?> get props => [id];
}
