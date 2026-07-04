import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
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
  ) : super(SMushafReader(
          fontMode: _settings.state.fontMode,
          theme: _settings.state.theme,
          fontScale: _settings.state.fontScale,
        )) {
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
  /// because the V4 glyphs/layout differ from V1/V2.
  void _watchSettings() {
    _settingsSub = _settings.stream.listen((s) {
      if (isClosed) return;
      if (s.theme != state.theme || s.fontScale != state.fontScale) {
        emit(state.copyWith(theme: s.theme, fontScale: s.fontScale));
      }
      // Colored (tajweedV4) and plain (plainV2) share the same page data and both
      // font variants are already registered, so a mode change just re-styles.
      if (s.fontMode != state.fontMode) emit(state.copyWith(fontMode: s.fontMode));
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

  Future<void> openPage(int page) async {
    if (page < 1 || page > 604) return;
    emit(
      state.copyWith(
        currentPage: page,
        status: LoadStatus.loading,
        fontMode: _settings.state.fontMode,
      ),
    );
    // Register the page's QPC-V4 colour font (+ background neighbour warmup) in
    // parallel with the layout resolve so glyphs are ready when we paint.
    final preloadFut = _fonts.preloadWindow(page);
    final layoutRes = await _getPage(page);
    await preloadFut;
    await layoutRes.fold(
      (failure) async {
        if (state.currentPage != page) return;
        emit(state.copyWith(status: LoadStatus.error, error: failure.message));
      },
      (layout) async {
        final surahNo = layout.allAyahRefs.firstOrNull?.surah ?? 1;
        final surahName = await _surahName(surahNo);
        if (state.currentPage != page) return;
        emit(
          state.copyWith(
            status: LoadStatus.success,
            layout: layout,
            surahName: surahName,
            juz: juzForPage(page),
          ),
        );
      },
    );
    if (state.currentPage == page) _scheduleLastReadSave(page);
  }

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
    emit(state.copyWith(chromeVisible: next, searchOpen: next && state.searchOpen));
  }

  /// Opens/closes the slide-down search panel. Opening keeps the chrome up so
  /// the panel stays anchored beneath the visible top bar.
  void toggleSearch() => emit(
        state.copyWith(searchOpen: !state.searchOpen, chromeVisible: true),
      );

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
