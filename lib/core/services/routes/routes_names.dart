/// Centralised, type-safe route names for the whole app.
///
/// Every route literal lives here — UI code calls `Modular.to.navigate(QuranRoutes.surahList)`,
/// never a raw string. Helpers like `readerFromAyah(2, 255)` build URLs with query params.
class RoutesNames {
  RoutesNames._();

  static const String splash = '/';
  static const String quranBase = '/quran/';
}

class QuranRoutes {
  QuranRoutes._();

  static const String surahList = '/';
  static const String reader = '/reader';
  static const String reciterPicker = '/reciter';
  static const String downloads = '/downloads';
  static const String bookmarks = '/bookmarks';
  static const String search = '/search';

  static String fullSurahList() => RoutesNames.quranBase;
  static String readerFromPage(int page) => '${RoutesNames.quranBase}reader?page=$page';
  static String readerFromAyah(int surah, int ayah) =>
      '${RoutesNames.quranBase}reader?surah=$surah&ayah=$ayah';
  static String fullReciterPicker() => '${RoutesNames.quranBase}reciter';
  static String fullDownloads() => '${RoutesNames.quranBase}downloads';
  static String fullBookmarks() => '${RoutesNames.quranBase}bookmarks';
  static String fullSearch() => '${RoutesNames.quranBase}search';
}
