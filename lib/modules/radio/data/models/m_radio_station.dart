import 'package:equatable/equatable.dart';

/// A single Quran radio station (a live audio stream).
///
/// Two origins feed this model (see the hybrid data layer):
/// - curated national broadcasts from [DSLocalRadio] (Egypt / Qatar / Saudi),
///   which carry a [flag], [country] and [frequency];
/// - live stations from the mp3quran.net API via [DSRemoteRadio], which only
///   carry an id, [name] and [url].
class MRadioStation extends Equatable {
  const MRadioStation({
    required this.id,
    required this.name,
    required this.url,
    this.nameEn,
    this.country,
    this.flag,
    this.frequency,
    this.isNational = false,
  });

  /// Builds a station from one entry of `GET /api/v3/radios` on mp3quran.net.
  /// Shape: `{ "id": 1, "name": "...", "url": "https://.../stream" }`.
  factory MRadioStation.fromMp3Quran(Map<String, dynamic> json) {
    return MRadioStation(
      id: 'mp3q_${json['id']}',
      name: (json['name'] ?? '').toString().trim(),
      url: (json['url'] ?? '').toString().trim(),
    );
  }

  final String id;

  /// Official station name (Arabic for national broadcasts).
  final String name;

  /// English/transliterated name, when available (national broadcasts only).
  final String? nameEn;

  /// Direct stream URL (icecast/mp3 or HLS `.m3u8` — both play via just_audio).
  final String url;

  /// Localised country label, e.g. "مصر" / "Egypt" (national broadcasts only).
  final String? country;

  /// Country flag emoji, e.g. "🇪🇬" (national broadcasts only).
  final String? flag;

  /// FM frequency label, e.g. "93.1 FM" (national broadcasts only).
  final String? frequency;

  /// True for the curated national "Holy Quran Radio" broadcasts.
  final bool isNational;

  /// Locale-aware display name: English name when present and the UI is LTR,
  /// otherwise the official (Arabic) name.
  String displayName({required bool isArabic}) {
    if (isArabic) return name;
    return (nameEn != null && nameEn!.isNotEmpty) ? nameEn! : name;
  }

  @override
  List<Object?> get props => [id, name, nameEn, url, country, flag, frequency, isNational];
}
