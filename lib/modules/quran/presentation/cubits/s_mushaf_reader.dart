import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

enum ReaderTheme { light, sepia, dark }

class SMushafReader extends Equatable {
  const SMushafReader({
    this.currentPage = 1,
    this.layout,
    this.status = LoadStatus.idle,
    this.error,
    this.selectedAyah,
    this.multiSelection = const <String>{},
    this.fontScale = 1.0,
    this.theme = ReaderTheme.light,
    this.surahName = '',
    this.juz = 1,
    this.chromeVisible = false,
    this.bookmarks = const <String, String?>{},
  });

  final int currentPage;
  final MPageLayout? layout;
  final LoadStatus status;
  final String? error;
  final ParamAyahRef? selectedAyah;
  final Set<String> multiSelection;
  final double fontScale;
  final ReaderTheme theme;

  /// Arabic name of the surah the current page belongs to (for the top bar).
  final String surahName;

  /// Juz' (1–30) the current page belongs to.
  final int juz;

  /// Whether the reader chrome (top and bottom controls) is visible. Tapping
  /// the page toggles it; selecting an ayah forces it on.
  final bool chromeVisible;

  /// Bookmarked ayahs on any page, keyed by `surah:ayah` → stored `colorHex`
  /// (may be null for colourless bookmarks). Kept live from the bookmarks box
  /// so saved ayahs stay highlighted in their colour.
  final Map<String, String?> bookmarks;

  SMushafReader copyWith({
    int? currentPage,
    MPageLayout? layout,
    LoadStatus? status,
    String? error,
    ParamAyahRef? selectedAyah,
    bool clearSelected = false,
    Set<String>? multiSelection,
    double? fontScale,
    ReaderTheme? theme,
    String? surahName,
    int? juz,
    bool? chromeVisible,
    Map<String, String?>? bookmarks,
  }) {
    return SMushafReader(
      currentPage: currentPage ?? this.currentPage,
      layout: layout ?? this.layout,
      status: status ?? this.status,
      error: error,
      selectedAyah: clearSelected ? null : (selectedAyah ?? this.selectedAyah),
      multiSelection: multiSelection ?? this.multiSelection,
      fontScale: fontScale ?? this.fontScale,
      theme: theme ?? this.theme,
      surahName: surahName ?? this.surahName,
      juz: juz ?? this.juz,
      chromeVisible: chromeVisible ?? this.chromeVisible,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    layout,
    status,
    error,
    selectedAyah,
    multiSelection,
    fontScale,
    theme,
    surahName,
    juz,
    chromeVisible,
    bookmarks,
  ];
}
