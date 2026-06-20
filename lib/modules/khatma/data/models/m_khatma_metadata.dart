import 'package:equatable/equatable.dart';

class MKhatmaMetadata extends Equatable {
  const MKhatmaMetadata({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.days,
    required this.path,
    required this.partsPerDay,
    required this.partsPerDayEn,
    required this.partsPerDayAr,
    required this.quartersPerDay,
    required this.quartersPerDayEn,
    required this.quartersPerDayAr,
    required this.isSuggested,
  });

  factory MKhatmaMetadata.fromJson(Map<String, dynamic> json) {
    return MKhatmaMetadata(
      id: json['id'] as int,
      nameEn: json['name_en'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      days: json['days'] as int? ?? 0,
      path: json['path'] as String? ?? '',
      partsPerDay: (json['parts_per_day'] as num?)?.toDouble() ?? 0,
      partsPerDayEn: json['parts_per_day_en'] as String? ?? '',
      partsPerDayAr: json['parts_per_day_ar'] as String? ?? '',
      quartersPerDay: (json['quarters_per_day'] as num?)?.toDouble() ?? 0,
      quartersPerDayEn: json['quarters_per_day_en'] as String? ?? '',
      quartersPerDayAr: json['quarters_per_day_ar'] as String? ?? '',
      isSuggested: json['is_suggested'] as bool? ?? false,
    );
  }

  final int id;
  final String nameEn;
  final String nameAr;
  final int days;
  final String path;
  final double partsPerDay;
  final String partsPerDayEn;
  final String partsPerDayAr;
  final double quartersPerDay;
  final String quartersPerDayEn;
  final String quartersPerDayAr;
  final bool isSuggested;

  @override
  List<Object?> get props => [id, path, days];
}

class MKhatmaWird extends Equatable {
  const MKhatmaWird({
    required this.index,
    required this.startAyahNumber,
    required this.endAyahNumber,
    required this.startAyahText,
    required this.endAyahText,
    required this.startSurahEn,
    required this.startSurahAr,
    required this.endSurahEn,
    required this.endSurahAr,
    required this.startPageNumber,
    required this.endPageNumber,
    this.startSurahNumber = 0,
    this.endSurahNumber = 0,
  });

  factory MKhatmaWird.fromJson(int index, Map<String, dynamic> json) {
    return MKhatmaWird(
      index: index,
      startAyahNumber: json['start_ayah_number'] as int? ?? 1,
      endAyahNumber: json['end_ayah_number'] as int? ?? 1,
      startAyahText: json['start_ayah_text'] as String? ?? '',
      endAyahText: json['end_ayah_text'] as String? ?? '',
      startSurahEn: json['start_surah_en'] as String? ?? '',
      startSurahAr: json['start_surah_ar'] as String? ?? '',
      endSurahEn: json['end_surah_en'] as String? ?? '',
      endSurahAr: json['end_surah_ar'] as String? ?? '',
      startPageNumber: json['start_page_number'] as int? ?? 1,
      endPageNumber: json['end_page_number'] as int? ?? 1,
    );
  }

  final int index;
  final int startAyahNumber;
  final int endAyahNumber;
  final String startAyahText;
  final String endAyahText;
  final String startSurahEn;
  final String startSurahAr;
  final String endSurahEn;
  final String endSurahAr;
  final int startPageNumber;
  final int endPageNumber;

  /// Quran surah numbers (1-114) for the range bounds. Resolved from the
  /// canonical surah list after parsing; 0 when unresolved.
  final int startSurahNumber;
  final int endSurahNumber;

  int get pageCount => endPageNumber - startPageNumber + 1;

  /// Returns a copy with the resolved surah numbers attached.
  MKhatmaWird withSurahNumbers({required int start, required int end}) =>
      MKhatmaWird(
        index: index,
        startAyahNumber: startAyahNumber,
        endAyahNumber: endAyahNumber,
        startAyahText: startAyahText,
        endAyahText: endAyahText,
        startSurahEn: startSurahEn,
        startSurahAr: startSurahAr,
        endSurahEn: endSurahEn,
        endSurahAr: endSurahAr,
        startPageNumber: startPageNumber,
        endPageNumber: endPageNumber,
        startSurahNumber: start,
        endSurahNumber: end,
      );

  @override
  List<Object?> get props => [
    index,
    startPageNumber,
    endPageNumber,
    startSurahNumber,
    endSurahNumber,
  ];
}
