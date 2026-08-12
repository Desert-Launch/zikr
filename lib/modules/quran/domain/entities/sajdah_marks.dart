/// The fifteen places of prostration (سجدات التلاوة) in the Hafs mushaf.
///
/// Ayah numbers and pages are taken from the bundled page layouts — every entry
/// here is a line in `assets/data/mushaf_pages/` that carries the printed sajdah
/// sign (۩), so the reader's marker always lands on the page the print does.
class SajdahMarks {
  SajdahMarks._();

  /// The sajdah sign as printed in the mushaf (U+06E9).
  static const String sign = '۩';

  /// Each row is `[surah, ayah, page]`.
  static const List<List<int>> rows = [
    [7, 206, 176], [13, 15, 251], [16, 50, 272], [17, 109, 293], //
    [19, 58, 309], [22, 18, 334], [22, 77, 341], [25, 60, 365], //
    [27, 26, 379], [32, 15, 416], [38, 24, 454], [41, 38, 480], //
    [53, 62, 528], [84, 21, 589], [96, 19, 597], //
  ];

  /// Whether the printed [page] (1..604) carries a sajdah.
  static bool onPage(int page) {
    for (final row in rows) {
      if (row[2] == page) return true;
    }
    return false;
  }

  /// Whether the given ayah is a sajdah ayah.
  static bool isSajdahAyah(int surah, int ayah) {
    for (final row in rows) {
      if (row[0] == surah && row[1] == ayah) return true;
    }
    return false;
  }
}
