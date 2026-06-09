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
    this.fullUrl,
    this.sizeBytes = 0,
    this.bundled = true,
    this.isDefault = false,
    this.license,
    this.author,
    this.sourceUrl,
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
        fullUrl: json['full_url'] as String?,
        sizeBytes: json['size_bytes'] as int? ?? 0,
        bundled: json['bundled'] as bool? ?? (json['asset'] != null),
        isDefault: json['is_default'] as bool? ?? false,
        license: json['license'] as String?,
        author: json['author'] as String?,
        sourceUrl: json['source_url'] as String?,
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

  /// Remote full-adhan URL (catalog-only voices). Null for purely bundled ones.
  final String? fullUrl;

  /// Download size in bytes (0 when unknown / bundled).
  final int sizeBytes;

  /// True when a bundled `asset` ships with the app.
  final bool bundled;

  /// True for the product default voice.
  final bool isDefault;

  /// Licensing provenance (required for CC-licensed audio). Surface
  /// [license] + [author] in the UI to satisfy attribution.
  final String? license;
  final String? author;
  final String? sourceUrl;

  /// One-line attribution, e.g. "CC BY-SA 4.0 · Fraguando". Empty when the
  /// voice carries no license metadata.
  String get attribution {
    final parts = [
      if (license?.isNotEmpty ?? false) license,
      if (author?.isNotEmpty ?? false) author,
    ];
    return parts.join(' · ');
  }

  /// Whether this voice can be fetched from the network — i.e. it isn't
  /// already bundled and has a remote URL. Bundled voices never show a
  /// download affordance.
  bool get isDownloadable => !bundled && (fullUrl?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [id];
}
