import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_hizb_entry.dart';

/// One juz' (1..30) of the mushaf, with the page where it begins and its two
/// ahzab.
class EJuzEntry extends Equatable {
  const EJuzEntry({
    required this.number,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
    required this.startSurahArabic,
    this.hizbs = const [],
  });

  /// Juz' number, 1..30.
  final int number;

  /// Surah number where the juz' begins.
  final int startSurah;

  /// Ayah number (within [startSurah]) where the juz' begins.
  final int startAyah;

  /// Madani-mushaf page (1..604) where the juz' begins.
  final int startPage;

  /// Arabic-script name of [startSurah], e.g. "البقرة".
  final String startSurahArabic;

  /// The two ahzab that make up this juz', in document order.
  final List<EHizbEntry> hizbs;

  @override
  List<Object?> get props => [number, startSurah, startAyah, startPage, hizbs];
}
