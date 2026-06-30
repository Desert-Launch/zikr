import 'package:equatable/equatable.dart';

/// One hizb (1..60) of the mushaf, with the page where it begins. Each juz'
/// contains two ahzab.
class EHizbEntry extends Equatable {
  const EHizbEntry({
    required this.number,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
    required this.startSurahArabic,
  });

  /// Hizb number, 1..60.
  final int number;

  /// Surah number where the hizb begins.
  final int startSurah;

  /// Ayah number (within [startSurah]) where the hizb begins.
  final int startAyah;

  /// Madani-mushaf page (1..604) where the hizb begins.
  final int startPage;

  /// Arabic-script name of [startSurah], e.g. "البقرة".
  final String startSurahArabic;

  @override
  List<Object?> get props => [number, startSurah, startAyah, startPage];
}
