import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_page_layout.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class CBMushafReader extends Cubit<SMushafReader> {
  CBMushafReader(
    this._getPage,
    this._saveLastRead,
    this._fonts,
    this._local,
    this._bookmarks,
  ) : super(const SMushafReader()) {
    _watchBookmarks();
  }

  final UCGetPageLayout _getPage;
  final UCSaveLastRead _saveLastRead;
  final DSQpcFontLoader _fonts;
  final DSLocalQuran _local;
  final RBookmarks _bookmarks;

  Timer? _saveDebounce;
  StreamSubscription<List<MBookmark>>? _bookmarkSub;

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

  static int _juzForPage(int page) {
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
    emit(state.copyWith(currentPage: page, status: LoadStatus.loading));
    // Preload fonts in parallel with layout JSON fetch.
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
            juz: _juzForPage(page),
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

  void toggleChrome() =>
      emit(state.copyWith(chromeVisible: !state.chromeVisible));

  void setChrome(bool visible) => emit(state.copyWith(chromeVisible: visible));

  void clearSelection() =>
      emit(state.copyWith(clearSelected: true, multiSelection: const {}));

  void toggleMultiSelect(ParamAyahRef ref) {
    final next = Set<String>.from(state.multiSelection);
    if (!next.add(ref.key)) next.remove(ref.key);
    emit(state.copyWith(multiSelection: next));
  }

  void setTheme(ReaderTheme theme) => emit(state.copyWith(theme: theme));
  void setFontScale(double scale) =>
      emit(state.copyWith(fontScale: scale.clamp(0.8, 1.5)));

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
    return super.close();
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
