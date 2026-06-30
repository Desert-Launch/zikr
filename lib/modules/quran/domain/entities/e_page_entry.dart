import 'package:equatable/equatable.dart';

/// One mushaf page (1..604), with the surah it belongs to.
class EPageEntry extends Equatable {
  const EPageEntry({
    required this.page,
    required this.surahNumber,
    required this.surahArabic,
  });

  /// Madani-mushaf page number, 1..604.
  final int page;

  /// Surah that this page falls in (the surah with the greatest `pageStart`
  /// that is `<= page`).
  final int surahNumber;

  /// Arabic-script name of [surahNumber], e.g. "البقرة".
  final String surahArabic;

  @override
  List<Object?> get props => [page, surahNumber];
}
