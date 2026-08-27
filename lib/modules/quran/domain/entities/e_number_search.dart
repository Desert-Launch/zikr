import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// One rub' (quarter-hizb) offered as a numeric-search result: where it begins
/// and the opening words printed there.
class ENumberRub extends Equatable {
  const ENumberRub({
    required this.hizb,
    required this.quarter,
    required this.ref,
    required this.page,
    required this.text,
  });

  /// Hizb number, 1..60.
  final int hizb;

  /// Which quarter of [hizb] this is: 1 the hizb's own start, then 2, 3, 4 for
  /// the quarter, half and three-quarter marks.
  final int quarter;

  /// Ayah the rub' begins at.
  final ParamAyahRef ref;

  /// Madani-mushaf page (1..604) the rub' begins on.
  final int page;

  /// Uthmani text of [ref] — the verse the rub' opens with.
  final String text;

  @override
  List<Object?> get props => [hizb, quarter, ref, page];
}

/// What a purely numeric query resolves to. Every section is independent: `50`
/// is at once a page, a surah and a hizb, so all three are offered and the
/// reader decides. Sections the number is out of range for come back null/empty
/// (e.g. `200` is a page but neither a surah nor a hizb).
class ENumberSearch extends Equatable {
  const ENumberSearch({
    required this.number,
    this.page,
    this.pageSurahArabic = '',
    this.pageSurahName = '',
    this.surah,
    this.rubs = const [],
  });

  /// The number that was typed.
  final int number;

  /// [number] read as a mushaf page, when it is 1..604.
  final int? page;

  /// Arabic-script name of the surah [page] opens in.
  final String pageSurahArabic;

  /// Transliterated name of the surah [page] opens in.
  final String pageSurahName;

  /// [number] read as a surah, when it is 1..114.
  final MSurah? surah;

  /// The four arba' of hizb [number], when it is 1..60. Empty otherwise.
  final List<ENumberRub> rubs;

  bool get isEmpty => page == null && surah == null && rubs.isEmpty;

  @override
  List<Object?> get props => [number, page, surah?.number, rubs];
}
