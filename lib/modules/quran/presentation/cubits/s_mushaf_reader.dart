import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class SMushafReader extends Equatable {
  const SMushafReader({
    this.currentPage = 1,
    this.pages = const <int, MQpcV4Page>{},
    this.status = LoadStatus.idle,
    this.error,
    this.selectedAyah,
    this.multiSelection = const <String>{},
    this.fontScale = 1.0,
    this.bold = false,
    this.theme = ReaderTheme.light,
    this.fontMode = EQuranFontMode.plainV2,
    this.scrollMode = EReaderScrollMode.horizontal,
    this.surahName = '',
    this.juz = 1,
    this.chromeVisible = false,
    this.searchOpen = false,
    this.bookmarks = const <String, String?>{},
    this.jumpRequest,
  });

  final int currentPage;

  /// Resolved page layouts kept warm around [currentPage] — a 7-page window
  /// (current ±3). Entries outside the window are evicted by
  /// [CBMushafReader.openPage], so this map never exceeds 7 pages regardless of
  /// how far the user swipes. Each entry is parsed glyph/segment data (no
  /// bitmaps), so the ceiling is a few hundred KB.
  final Map<int, MQpcV4Page> pages;

  /// The current page's layout, or `null` while it resolves.
  MQpcV4Page? get layout => pages[currentPage];

  final LoadStatus status;
  final String? error;
  final ParamAyahRef? selectedAyah;
  final Set<String> multiSelection;
  final double fontScale;

  /// Heavier glyph weight for the Mushaf text; mirrors [CBReaderSettings].
  final bool bold;

  final ReaderTheme theme;

  /// Which QPC font set the current [layout] was loaded for. Drives glyph
  /// selection + font family in the renderer; mirrors [CBReaderSettings].
  final EQuranFontMode fontMode;

  /// Whether the reader pages sideways or scrolls as one continuous column;
  /// mirrors [CBReaderSettings]. Only [SNMushafReader] acts on it — it owns
  /// both scroll controllers.
  final EReaderScrollMode scrollMode;

  /// Arabic name of the surah the current page belongs to (for the top bar).
  final String surahName;

  /// Juz' (1–30) the current page belongs to.
  final int juz;

  /// Whether the reader chrome (top and bottom controls) is visible. Tapping
  /// the page toggles it; selecting an ayah forces it on.
  final bool chromeVisible;

  /// Whether the slide-down search panel under the top bar is open.
  final bool searchOpen;

  /// Bookmarked ayahs on any page, keyed by `surah:ayah` → stored `colorHex`
  /// (may be null for colourless bookmarks). Kept live from the bookmarks box
  /// so saved ayahs stay highlighted in their colour.
  final Map<String, String?> bookmarks;

  /// A verse some widget deep in the reader (bookmarks sheet, colour picker)
  /// asked to navigate to. Only [SNMushafReader] owns the `PageController`, so
  /// it watches this, jumps, and clears it via
  /// [CBMushafReader.consumeJumpRequest]. `null` means nothing pending.
  final ParamAyahRef? jumpRequest;

  SMushafReader copyWith({
    int? currentPage,
    Map<int, MQpcV4Page>? pages,
    LoadStatus? status,
    String? error,
    ParamAyahRef? selectedAyah,
    bool clearSelected = false,
    Set<String>? multiSelection,
    double? fontScale,
    bool? bold,
    ReaderTheme? theme,
    EQuranFontMode? fontMode,
    EReaderScrollMode? scrollMode,
    String? surahName,
    int? juz,
    bool? chromeVisible,
    bool? searchOpen,
    Map<String, String?>? bookmarks,
    ParamAyahRef? jumpRequest,
    bool clearJumpRequest = false,
  }) {
    return SMushafReader(
      currentPage: currentPage ?? this.currentPage,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      error: error,
      selectedAyah: clearSelected ? null : (selectedAyah ?? this.selectedAyah),
      multiSelection: multiSelection ?? this.multiSelection,
      fontScale: fontScale ?? this.fontScale,
      bold: bold ?? this.bold,
      theme: theme ?? this.theme,
      fontMode: fontMode ?? this.fontMode,
      scrollMode: scrollMode ?? this.scrollMode,
      surahName: surahName ?? this.surahName,
      juz: juz ?? this.juz,
      chromeVisible: chromeVisible ?? this.chromeVisible,
      searchOpen: searchOpen ?? this.searchOpen,
      bookmarks: bookmarks ?? this.bookmarks,
      jumpRequest: clearJumpRequest ? null : (jumpRequest ?? this.jumpRequest),
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    pages,
    status,
    error,
    selectedAyah,
    multiSelection,
    fontScale,
    bold,
    theme,
    fontMode,
    scrollMode,
    surahName,
    juz,
    chromeVisible,
    searchOpen,
    bookmarks,
    jumpRequest,
  ];
}
