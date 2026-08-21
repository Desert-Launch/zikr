import 'package:quran/modules/azkar/domain/entities/e_azkar_audio.dart';

/// The curated source catalogue — **the one file you edit to add a sheikh**.
///
/// Every reader here was probed by hand before being written down: the URLs
/// answered with real `audio/*` bytes, and the item title names the reciter.
/// Nothing is listed because a recording "supposedly exists" somewhere.
///
/// Two kinds of reader:
///   • [hisnMuslim] — the official Hisn al-Muslim API, which publishes one MP3
///     per dhikr, so its entries are matched to our adhkar by text.
///   • [archiveItems] — Internet Archive items holding whole-sitting
///     recordings. Their category attachment is declared here by a human who
///     read the file title, and is therefore recorded as `manual` confidence.
class ReaderSource {
  const ReaderSource({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sourceName,
    required this.sourceUrl,
    required this.license,
    required this.licenseStatus,
    required this.attribution,
    this.descriptionAr,
    this.descriptionEn,
    this.hisnMuslim = false,
    this.archiveItems = const <ArchiveRecording>[],
    this.manualOverrides = const <String, String>{},
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String sourceName;
  final String sourceUrl;
  final String license;
  final EAzkarLicenseStatus licenseStatus;
  final String attribution;
  final String? descriptionAr;
  final String? descriptionEn;

  /// Import the per-dhikr catalogue from hisnmuslim.com for this reader.
  final bool hisnMuslim;

  /// Whole-sitting recordings hosted on archive.org.
  final List<ArchiveRecording> archiveItems;

  /// `adhkarId` → source record id, for pairs the matcher cannot be trusted to
  /// find on its own. Empty today; the plumbing is here for future corrections.
  final Map<String, String> manualOverrides;
}

/// One file inside an Internet Archive item, and the sittings it covers.
class ArchiveRecording {
  const ArchiveRecording({
    required this.itemId,
    required this.fileName,
    required this.titleAr,
    required this.categoryIds,
  });

  final String itemId;
  final String fileName;

  /// The source's own wording, shown verbatim in the UI so the user always
  /// knows what a whole-sitting file actually contains.
  final String titleAr;

  /// App category ids this file belongs to. Two entries where the recording
  /// genuinely covers two sittings ("أذكار الصباح والمساء") — one file, two
  /// entry points, never a fabricated split.
  final List<String> categoryIds;

  /// archive.org serves item files from a stable path that 302s to whichever
  /// node holds the item.
  String get url =>
      'https://archive.org/download/$itemId/${Uri.encodeComponent(fileName)}';

  String get itemUrl => 'https://archive.org/details/$itemId';
}

/// Shorthand for the two sittings covered by a combined morning+evening file.
const List<String> _morningAndEvening = <String>['morning', 'evening'];

/// Licence note reused by every archive.org item below: the uploads are
/// publicly served with no licence statement, so nothing is bundled into the
/// app package — files are fetched from archive.org on the user's request and
/// the source item stays credited.
const String _archiveLicenseNote =
    'No licence statement on the source item. Streamed/downloaded from '
    'archive.org on request; never bundled into the app package.';

const List<ReaderSource> readerSources = <ReaderSource>[
  ReaderSource(
    id: 'hamad-al-duraihem',
    nameAr: 'حمد الدريهم',
    nameEn: 'Hamad Al-Duraihem',
    descriptionAr: 'التسجيل الصوتي لكتاب حصن المسلم — ذكر مستقل لكل دعاء.',
    descriptionEn:
        'The Hisn al-Muslim audio recording — one file per individual dhikr.',
    sourceName: 'حصن المسلم — hisnmuslim.com',
    sourceUrl: 'https://www.hisnmuslim.com/',
    license: 'No licence statement published on the source site.',
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'حصن المسلم — تسجيل حمد الدريهم (hisnmuslim.com)',
    hisnMuslim: true,
  ),
  ReaderSource(
    id: 'mishary-alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    sourceName: 'archive.org',
    sourceUrl:
        'https://archive.org/details/1434-mishari-alafasy-azkar-sabah-1434-a-h',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'مشاري راشد العفاسي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: '1434-mishari-alafasy-azkar-sabah-1434-a-h',
        fileName:
            '#مشاري_راشد_العفاسي أذكار الصباح لعام 1434هـ - Mishari Alafasy Azkar Sabah 1434A H.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
      ArchiveRecording(
        itemId: '1434-mishari-alafasy-azkar-sabah-1434-a-h',
        fileName:
            "#مشاري_راشد_العفاسي أذكار المساء لعام 1434هـ - Mishari Alafasy Azkar Almasa' 1434A H.mp3",
        titleAr: 'أذكار المساء',
        categoryIds: <String>['evening'],
      ),
    ],
  ),
  ReaderSource(
    id: 'fares-abbad',
    nameAr: 'فارس عباد',
    nameEn: 'Fares Abbad',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/adhkar-alsabah-walmasa-faris-abaad',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'فارس عباد — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'adhkar-alsabah-walmasa-faris-abaad',
        fileName: 'أذكار الصباح.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
      ArchiveRecording(
        itemId: 'adhkar-alsabah-walmasa-faris-abaad',
        fileName: 'أذكار المساء.mp3',
        titleAr: 'أذكار المساء',
        categoryIds: <String>['evening'],
      ),
    ],
  ),
  ReaderSource(
    id: 'muhammad-jibril',
    nameAr: 'محمد جبريل',
    nameEn: 'Muhammad Jibril',
    sourceName: 'archive.org',
    sourceUrl:
        'https://archive.org/details/adhkar-alsabah-walmasa-muhamad-jibril',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'محمد جبريل — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'adhkar-alsabah-walmasa-muhamad-jibril',
        fileName: 'أذكار الصباح.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
      ArchiveRecording(
        itemId: 'adhkar-alsabah-walmasa-muhamad-jibril',
        fileName: 'أذكار المساء.mp3',
        titleAr: 'أذكار المساء',
        categoryIds: <String>['evening'],
      ),
    ],
  ),
  ReaderSource(
    id: 'maher-al-muaiqly',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/Moath_a4_hotmail_20131010',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'ماهر المعيقلي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'Moath_a4_hotmail_20131010',
        fileName: 'أذكار الصباح - ماهر المعيقلي.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
      ArchiveRecording(
        itemId: 'Moath_a4_hotmail_20131010_2225',
        fileName: 'أذكار النوم - ماهر المعيقلي.mp3',
        titleAr: 'أذكار النوم',
        categoryIds: <String>['sleeping'],
      ),
    ],
  ),
  ReaderSource(
    id: 'saad-al-ghamdi',
    nameAr: 'سعد الغامدي',
    nameEn: 'Saad Al-Ghamdi',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/20250607_20250607_1005',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'سعد الغامدي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: '20250607_20250607_1005',
        fileName: 'أذكار الصباح للشيخ سعد الغامدي.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
    ],
  ),
  ReaderSource(
    id: 'yasser-al-dosari',
    nameAr: 'ياسر الدوسري',
    nameEn: 'Yasser Al-Dosari',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/20250607_20250607_0959',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'ياسر الدوسري — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: '20250607_20250607_0959',
        // Two spaces after "الصباح" — the uploader's filename, kept verbatim
        // because archive.org paths are byte-exact.
        fileName: 'أذكار الصباح  بصوت الشيخ ياسر الدوسري.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
    ],
  ),
  ReaderSource(
    id: 'salman-al-otaibi',
    nameAr: 'سلمان العتيبي',
    nameEn: 'Salman Al-Otaibi',
    sourceName: 'archive.org',
    sourceUrl:
        'https://archive.org/details/Bvtrtyuiouyuewtuiouioiyrbvcrettyiooppuioytriy1433_gmail_201801',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'سلمان العتيبي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'Bvtrtyuiouyuewtuiouioiyrbvcrettyiooppuioytriy1433_gmail_201801',
        fileName: 'اذكار الصباح بصوت سلمان العتيبى تلاوة مبكية خاشعة.mp3',
        titleAr: 'أذكار الصباح',
        categoryIds: <String>['morning'],
      ),
      ArchiveRecording(
        itemId: 'Bvtrtyuiouyuewtuiouioiyrbvcrettyiooppuioytriy1433_gmail_201801',
        fileName: 'اذكار المساء بصوت سلمان العتيبى تلاوة مبكية خاشعة.mp3',
        titleAr: 'أذكار المساء',
        categoryIds: <String>['evening'],
      ),
    ],
  ),
  ReaderSource(
    id: 'idris-abkar',
    nameAr: 'إدريس أبكر',
    nameEn: 'Idris Abkar',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/Athka247424724724475dreesAbkar',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'إدريس أبكر — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'Athka247424724724475dreesAbkar',
        fileName: 'Athkar Idrees Abkar.mp3',
        titleAr: 'أذكار الصباح والمساء',
        categoryIds: _morningAndEvening,
      ),
    ],
  ),
  ReaderSource(
    id: 'hani-al-rifai',
    nameAr: 'هاني الرفاعي',
    nameEn: 'Hani Al-Rifai',
    sourceName: 'archive.org',
    sourceUrl: 'https://archive.org/details/AthkarHani247247247247245242aei',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'هاني الرفاعي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'AthkarHani247247247247245242aei',
        fileName: 'Athkar Hani Alrefaei.mp3',
        titleAr: 'أذكار الصباح والمساء',
        categoryIds: _morningAndEvening,
      ),
    ],
  ),
  ReaderSource(
    id: 'nasser-al-qatami',
    nameAr: 'ناصر القطامي',
    nameEn: 'Nasser Al-Qatami',
    sourceName: 'archive.org',
    sourceUrl:
        'https://archive.org/details/adhkar-alyawm-wallayl-nasir-alqataami',
    license: _archiveLicenseNote,
    licenseStatus: EAzkarLicenseStatus.unknown,
    attribution: 'ناصر القطامي — أرشيف الإنترنت',
    archiveItems: <ArchiveRecording>[
      ArchiveRecording(
        itemId: 'adhkar-alyawm-wallayl-nasir-alqataami',
        fileName: 'أذكار اليوم والليلة.mp3',
        titleAr: 'أذكار اليوم والليلة',
        categoryIds: _morningAndEvening,
      ),
    ],
  ),
];
