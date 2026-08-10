import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class CBMushafReader extends Cubit<SMushafReader> {
  CBMushafReader(
    this._getPage,
    this._saveLastRead,
    this._fonts,
    this._local,
    this._bookmarks,
    this._settings,
  ) : super(
        SMushafReader(
          fontMode: _settings.state.fontMode,
          theme: _settings.state.theme,
          fontScale: _settings.state.fontScale,
          bold: _settings.state.bold,
          scrollMode: _settings.state.scrollMode,
        ),
      ) {
    _watchBookmarks();
    _watchSettings();
  }

  final UCGetQpcV4Page _getPage;
  final UCSaveLastRead _saveLastRead;
  final DSQpcV4FontLoader _fonts;
  final DSLocalQuran _local;
  final RBookmarks _bookmarks;
  final CBReaderSettings _settings;

  Timer? _saveDebounce;
  StreamSubscription<List<MBookmark>>? _bookmarkSub;
  StreamSubscription<SReaderSettings>? _settingsSub;

  /// Mirrors the shared [CBReaderSettings] into the reader state so changes made
  /// on the settings screen apply to an open reader instantly. Theme and text
  /// size just re-style the current page; a font-mode change reloads the page
  /// because the V4 glyphs/layout differ from V1/V2. A scroll-mode change swaps
  /// the reader's whole scroll view, which is why the screen — not this cubit —
  /// re-seats it on [SMushafReader.currentPage] afterwards.
  void _watchSettings() {
    _settingsSub = _settings.stream.listen((s) {
      if (isClosed) return;
      if (s.theme != state.theme ||
          s.fontScale != state.fontScale ||
          s.bold != state.bold ||
          s.scrollMode != state.scrollMode) {
        emit(
          state.copyWith(
            theme: s.theme,
            fontScale: s.fontScale,
            bold: s.bold,
            scrollMode: s.scrollMode,
          ),
        );
      }
      // Colored (tajweedV4) and plain (plainV2) share the same page data and both
      // font variants are already registered, so a mode change just re-styles.
      if (s.fontMode != state.fontMode) {
        emit(state.copyWith(fontMode: s.fontMode));
      }
    });
  }

  /// Seeds the bookmark highlights, then keeps them in sync with the box so a
  /// verse saved from the action sheet lights up immediately and stays lit.
  void _watchBookmarks() {
    _bookmarks.list().then((res) {
      res.fold((_) {}, (all) {
        if (!isClosed) emit(state.copyWith(bookmarks: _mapOf(all)));
      });
    });
    _bookmarkSub = _bookmarks.watch().listen((all) {
      if (!isClosed) emit(state.copyWith(bookmarks: _mapOf(all)));
    });
  }

  Map<String, String?> _mapOf(List<MBookmark> all) => {
    for (final b in all) b.ayahKey: b.colorHex,
  };

  /// First page of every juz' in the 604-page Madani Mushaf. Index 0 → juz' 1.
  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, //
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382, //
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582, //
  ];

  /// The juz' (1–30) a Madani-Mushaf [page] (1–604) belongs to, by its start
  /// page. Public so the page chrome can label each page without re-deriving it.
  static int juzForPage(int page) {
    var juz = 1;
    for (var i = 0; i < _juzStartPages.length; i++) {
      if (page >= _juzStartPages[i]) {
        juz = i + 1;
      } else {
        break;
      }
    }
    return juz;
  }

  /// How many pages either side of the current one are resolved and kept in
  /// [SMushafReader.pages]. 3 before + current + 3 after = a 7-page window.
  static const int preloadRadius = 3;

  static const int _firstPage = 1;
  static const int _lastPage = 604;

  /// Pages whose layout resolve is already in flight, so a swipe back and forth
  /// across the window doesn't fire duplicate reads.
  final Set<int> _inFlight = <int>{};

  Future<void> openPage(int page) async {
    if (page < _firstPage || page > _lastPage) return;
    final cached = state.pages[page];
    emit(
      state.copyWith(
        currentPage: page,
        // Already warm from a previous preload — no spinner, paint immediately.
        status: cached != null ? LoadStatus.success : LoadStatus.loading,
        pages: _evictOutsideWindow(state.pages, page),
        surahName: cached != null ? state.surahName : '',
        juz: juzForPage(page),
        fontMode: _settings.state.fontMode,
      ),
    );
    // Register the page's QPC-V4 colour font (+ background neighbour warmup) in
    // parallel with the layout resolve so glyphs are ready when we paint.
    final preloadFut = _fonts.preloadWindow(page);
    final ok = cached != null ? true : await _resolve(page);
    await preloadFut;
    if (state.currentPage != page) return;
    if (ok) {
      final surahNo = state.pages[page]?.allAyahRefs.firstOrNull?.surah ?? 1;
      final surahName = await _surahName(surahNo);
      if (state.currentPage != page) return;
      emit(state.copyWith(status: LoadStatus.success, surahName: surahName));
      _scheduleLastReadSave(page);
    }
    // Warm the neighbours only after the visible page is on screen, so the
    // swipe the user is watching never waits on a page they can't see.
    unawaited(_preloadWindow(page));
  }

  /// Resolves [page]'s layout into the cache. Returns whether it succeeded.
  /// Only the *current* page's failure surfaces as an error state — a neighbour
  /// that fails to preload is simply retried when it becomes current.
  Future<bool> _resolve(int page) async {
    if (_inFlight.contains(page)) return state.pages.containsKey(page);
    _inFlight.add(page);
    try {
      final res = await _getPage(page);
      if (isClosed) return false;
      return res.fold(
        (failure) {
          if (state.currentPage == page) {
            emit(
              state.copyWith(status: LoadStatus.error, error: failure.message),
            );
          }
          return false;
        },
        (layout) {
          // Re-check the window: the user may have swiped far away while this
          // was resolving, in which case the page no longer belongs in cache.
          if (!_inWindow(page, state.currentPage)) return false;
          emit(state.copyWith(pages: {...state.pages, page: layout}));
          return true;
        },
      );
    } finally {
      _inFlight.remove(page);
    }
  }

  /// Resolves the ±[preloadRadius] neighbours of [centre], nearest first, so a
  /// swipe in either direction lands on an already-parsed page.
  Future<void> _preloadWindow(int centre) async {
    for (var distance = 1; distance <= preloadRadius; distance++) {
      for (final page in [centre - distance, centre + distance]) {
        if (page < _firstPage || page > _lastPage) continue;
        if (isClosed || state.currentPage != centre) return;
        if (state.pages.containsKey(page)) continue;
        await _resolve(page);
      }
    }
  }

  bool _inWindow(int page, int centre) =>
      (page - centre).abs() <= preloadRadius;

  /// Drops cached layouts that fell outside the window — this is what keeps
  /// memory flat as the user reads through the mushaf.
  Map<int, MQpcV4Page> _evictOutsideWindow(
    Map<int, MQpcV4Page> current,
    int centre,
  ) {
    final kept = <int, MQpcV4Page>{
      for (final entry in current.entries)
        if (_inWindow(entry.key, centre)) entry.key: entry.value,
    };
    return kept.length == current.length ? current : kept;
  }

  /// Saves [ref] with [colorHex], replacing any colour it already carries.
  /// Highlights refresh through the bookmark watch stream.
  Future<void> saveBookmark(ParamAyahRef ref, String colorHex) =>
      _bookmarks.save(ref: ref, colorHex: colorHex);

  /// Un-bookmarks [ref] (the picker's toggle-off).
  Future<void> removeBookmark(ParamAyahRef ref) => _bookmarks.deleteByAyah(ref);

  bool isBookmarked(ParamAyahRef ref) => state.bookmarks.containsKey(ref.key);

  /// Asks the open reader to navigate to [ref]. Widgets nested under the reader
  /// (the bookmarks sheet, the colour picker) can't reach the `PageController`,
  /// so they raise the request here and the screen performs the jump.
  void requestJumpToAyah(ParamAyahRef ref) {
    emit(state.copyWith(jumpRequest: ref, clearSelected: true));
  }

  /// Clears a handled [SMushafReader.jumpRequest] so the same verse can be
  /// requested again later.
  void consumeJumpRequest() {
    if (state.jumpRequest == null) return;
    emit(state.copyWith(clearJumpRequest: true));
  }

  /// The colour [ref] is bookmarked with, or `null` (not bookmarked, or a
  /// legacy colourless bookmark).
  String? bookmarkColorOf(ParamAyahRef ref) => state.bookmarks[ref.key];

  Future<String> _surahName(int number) async {
    try {
      final surahs = await _local.loadSurahs();
      for (final s in surahs) {
        if (s.number == number) {
          return s.arabicLong.isNotEmpty ? s.arabicLong : s.arabic;
        }
      }
    } catch (_) {
      // Best-effort — the top bar simply shows no name on lookup failure.
    }
    return '';
  }

  /// Highlights [ref] without revealing the chrome or opening the action
  /// sheet. Used when the reader is deep-linked to a specific ayah (e.g. the
  /// verse-of-the-day card) so the verse is highlighted but nothing pops up.
  void highlightAyah(ParamAyahRef ref) =>
      emit(state.copyWith(selectedAyah: ref));

  void selectAyah(ParamAyahRef ref) {
    if (state.selectedAyah?.key == ref.key) {
      emit(state.copyWith(clearSelected: true));
    } else {
      // Selecting an ayah opens the bottom action sheet and reveals the chrome.
      emit(state.copyWith(selectedAyah: ref, chromeVisible: true));
    }
  }

  void toggleChrome() {
    final next = !state.chromeVisible;
    // Hiding the chrome also dismisses the search panel so it never floats
    // without the top bar it anchors to.
    emit(
      state.copyWith(chromeVisible: next, searchOpen: next && state.searchOpen),
    );
  }

  /// Opens/closes the slide-down search panel. Opening keeps the chrome up so
  /// the panel stays anchored beneath the visible top bar.
  void toggleSearch() =>
      emit(state.copyWith(searchOpen: !state.searchOpen, chromeVisible: true));

  void closeSearch() => emit(state.copyWith(searchOpen: false));

  void setChrome(bool visible) => emit(state.copyWith(chromeVisible: visible));

  void clearSelection() =>
      emit(state.copyWith(clearSelected: true, multiSelection: const {}));

  void toggleMultiSelect(ParamAyahRef ref) {
    final next = Set<String>.from(state.multiSelection);
    if (!next.add(ref.key)) next.remove(ref.key);
    emit(state.copyWith(multiSelection: next));
  }

  void _scheduleLastReadSave(int page) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 5), () {
      final layout = state.layout;
      final first = layout?.allAyahRefs.firstOrNull;
      _saveLastRead(
        surah: first?.surah ?? 1,
        ayah: first?.ayah ?? 1,
        page: page,
      );
    });
  }

  @override
  Future<void> close() {
    _saveDebounce?.cancel();
    _bookmarkSub?.cancel();
    _settingsSub?.cancel();
    return super.close();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
