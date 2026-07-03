import 'package:equatable/equatable.dart';

/// A single tafsir (Quran commentary) book in the catalogue.
///
/// Books are sourced from the Quranic Universal Library (QUL). Each book maps to
/// one downloadable file at [fullPath] (a base64-encoded BZip2 JSON keyed by
/// `surah:ayah`). [id] is a stable, storage-safe key we assign; it is what the
/// downloaded blob is stored under, so it must never change once shipped.
class ETafsirBook extends Equatable {
  const ETafsirBook({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.name,
    required this.fullPath,
  });

  /// Stable storage/id key, e.g. `en-mukhtasar`. Never change post-release.
  final String id;

  /// Display language, e.g. `English`, `العربية`.
  final String language;

  /// ISO code, e.g. `en`, `ar`. Drives text direction in the reader.
  final String languageCode;

  /// Display name of the book, e.g. `Al-Mukhtasar`.
  final String name;

  /// QUL path appended to [EndPoints.tafsirBase] to download the book.
  final String fullPath;

  bool get isRtl => languageCode == 'ar' || languageCode == 'ur' || languageCode == 'fa';

  @override
  List<Object?> get props => [id, fullPath];
}

/// The curated tafsir catalogue shipped with the app.
///
/// A focused subset of the ~104 QUL books, spanning the languages the app
/// targets first. Add more entries here — `full_path` values come straight from
/// the QUL `compressed_tafsir_v2` tree.
class TafsirCatalog {
  TafsirCatalog._();

  static const String _root = 'quranic_universal_library/compressed_tafsir_v2';

  static const List<ETafsirBook> books = [
    // ---- Arabic ----
    ETafsirBook(
      id: 'ar-muyassar',
      language: 'العربية',
      languageCode: 'ar',
      name: 'التفسير الميسّر',
      fullPath: '$_root/Arabic/Tafsir_Muyassar.json.txt',
    ),
    ETafsirBook(
      id: 'ar-saadi',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير السعدي',
      fullPath: '$_root/Arabic/Tafsir_As-Saadi.json.txt',
    ),
    ETafsirBook(
      id: 'ar-ibnkathir',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير ابن كثير',
      fullPath: '$_root/Arabic/Tafsir_Ibn_Kathir.json.txt',
    ),
    ETafsirBook(
      id: 'ar-mukhtasar',
      language: 'العربية',
      languageCode: 'ar',
      name: 'المختصر في التفسير',
      fullPath: '$_root/Arabic/Arabic_Al-Mukhtasar_in_interpreting_the_Noble_Quran.json.txt',
    ),
    ETafsirBook(
      id: 'ar-tabari',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير الطبري',
      fullPath: '$_root/Arabic/Tafsir_al-Tabari.json.txt',
    ),
    ETafsirBook(
      id: 'ar-qurtubi',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير القرطبي',
      fullPath: '$_root/Arabic/Tafseer_Al_Qurtubi.json.txt',
    ),
    ETafsirBook(
      id: 'ar-baghawi',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير البغوي',
      fullPath: '$_root/Arabic/Tafseer_Al-Baghawi.json.txt',
    ),
    ETafsirBook(
      id: 'ar-jalalayn',
      language: 'العربية',
      languageCode: 'ar',
      name: 'تفسير الجلالين',
      fullPath: '$_root/Arabic/Tafsir_Jalalayn.json.txt',
    ),

    // ---- English ----
    ETafsirBook(
      id: 'en-mukhtasar',
      language: 'English',
      languageCode: 'en',
      name: 'Al-Mukhtasar',
      fullPath: '$_root/English/English_Al-Mukhtasar.json.txt',
    ),
    ETafsirBook(
      id: 'en-ibnkathir',
      language: 'English',
      languageCode: 'en',
      name: 'Tafsir Ibn Kathir',
      fullPath: '$_root/English/Tafsir_Ibn_Kathir.json.txt',
    ),
    ETafsirBook(
      id: 'en-maarif',
      language: 'English',
      languageCode: 'en',
      name: 'Maarif-ul-Quran',
      fullPath: '$_root/English/Maarif-ul-Quran.json.txt',
    ),
    ETafsirBook(
      id: 'en-tazkirul',
      language: 'English',
      languageCode: 'en',
      name: 'Tazkirul Quran',
      fullPath: '$_root/English/Tazkirul_Quran(Maulana_Wahiduddin_Khan).json.txt',
    ),

    // ---- Urdu ----
    ETafsirBook(
      id: 'ur-saadi',
      language: 'اردو',
      languageCode: 'ur',
      name: 'تفسیر السعدی',
      fullPath: '$_root/Urdu/Tafsir_As-Saadi_-_Urdu.json.txt',
    ),
    ETafsirBook(
      id: 'ur-bayan',
      language: 'اردو',
      languageCode: 'ur',
      name: 'تفسیر بیان القرآن',
      fullPath: '$_root/Urdu/Tafsir_Bayan_ul_Quran.json.txt',
    ),
    ETafsirBook(
      id: 'ur-fizilal',
      language: 'اردو',
      languageCode: 'ur',
      name: 'فی ظلال القرآن',
      fullPath: '$_root/Urdu/Fi_Zilal_al-Quran.json.txt',
    ),

    // ---- French ----
    ETafsirBook(
      id: 'fr-mukhtasar',
      language: 'Français',
      languageCode: 'fr',
      name: 'Al-Mukhtasar',
      fullPath: '$_root/French/French_Abridged_Explanation_of_the_Quran.json.txt',
    ),

    // ---- Indonesian ----
    ETafsirBook(
      id: 'id-mukhtasar',
      language: 'Indonesia',
      languageCode: 'id',
      name: 'Al-Mukhtasar',
      fullPath: '$_root/Indonesian/Indoniesua_Al-Mukhtasar_in_Interpreting_the_Noble_Quran.json.txt',
    ),
    ETafsirBook(
      id: 'id-saadi',
      language: 'Indonesia',
      languageCode: 'id',
      name: 'Tafsir As-Saadi',
      fullPath: '$_root/Indonesian/Tafsir_As-Saadi.json.txt',
    ),

    // ---- Turkish ----
    ETafsirBook(
      id: 'tr-saadi',
      language: 'Türkçe',
      languageCode: 'tr',
      name: 'Tafsir As-Saadi',
      fullPath: '$_root/Turkish/Tafsir_As-Saadi_-_Turkish.json.txt',
    ),

    // ---- Bengali ----
    ETafsirBook(
      id: 'bn-zakaria',
      language: 'বাংলা',
      languageCode: 'bn',
      name: 'Tafsir Abu Bakr Zakaria',
      fullPath: '$_root/Bengali/Tafsir_Abu_Bakr_Zakaria.json.txt',
    ),
  ];

  /// Fast id lookup (e.g. to hydrate a downloaded-book id back to its metadata).
  static ETafsirBook? byId(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }
}
