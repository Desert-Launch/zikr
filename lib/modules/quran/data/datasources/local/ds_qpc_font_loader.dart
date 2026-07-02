import 'dart:async';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';

/// Registers per-page QPC TTF fonts on demand.
///
/// Strategy:
/// - Each page N uses font family `QCF_V2_P{N}` (loaded from
///   `assets/fonts/qpc_v2/QCF_V2_P{NNN}.TTF`) — the standard Madani Mushaf set.
/// - The loader maintains a window of recently-used fonts. Anything past
///   [_maxLoadedPages] entries is left in memory until the OS evicts it
///   (Flutter cannot unload a registered `FontLoader`).
class DSQpcFontLoader {
  DSQpcFontLoader();

  static const int _maxLoadedPages = 9; // current ± 4

  /// The standard (plain V2) per-page family — what callers that always render
  /// the plain Mushaf (basmala line, tajweed ayah-end rosette) use directly.
  static String pageFamily(int page) => 'QCF_V2_P$page';

  /// Per-page family for the given [mode] — what the renderer must set as the
  /// `fontFamily` for that mode's glyphs.
  static String familyFor(int page, EQuranFontMode mode) =>
      mode.fontFamilyForPage(page);

  // Track loaded font *families* (not page numbers): the same page renders
  // under different families per mode (e.g. QCF_P5 vs QCF_V4_P5).
  final Set<String> _loadedFamilies = <String>{};
  bool _basmalaLoaded = false;
  final Map<String, Future<void>> _inFlight = {};

  /// Returns once the font for [page] in [mode] is registered. No-op if loaded.
  Future<void> loadPage(int page, [EQuranFontMode mode = EQuranFontMode.plainV2]) {
    if (page < 1 || page > 604) return Future.value();
    final family = familyFor(page, mode);
    if (_loadedFamilies.contains(family)) return Future.value();
    final existing = _inFlight[family];
    if (existing != null) return existing;
    final f = _loadFontInternal(page, mode, family);
    _inFlight[family] = f;
    return f.whenComplete(() => _inFlight.remove(family));
  }

  Future<void> _loadFontInternal(
    int page,
    EQuranFontMode mode,
    String family,
  ) async {
    try {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(mode.assetForPage(page)));
      await loader.load();
      _loadedFamilies.add(family);

      // Best-effort bookkeeping. Flutter has no unload API for runtime fonts,
      // so this bound is informational — we just stop tracking the oldest.
      if (_loadedFamilies.length > _maxLoadedPages) {
        _loadedFamilies.remove(_loadedFamilies.first);
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed loading QPC page font $page ($family)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Loads the typography we use for every basmala line.
  ///
  /// Every basmala line is drawn using Al-Fatihah's basmala glyphs
  /// (`ﱁ ﱂ ﱃ ﱄ`) and the page-1 font (`QCF_V2_P1`), which always exists in the
  /// bundled QPC V2 set — giving identical calligraphy to the printed Madani copy.
  Future<void> loadBasmala() async {
    if (_basmalaLoaded) return;
    await loadPage(1);
    _basmalaLoaded = true;
  }

  /// Preload the visible page + a window of neighbours for [mode]. Returns the
  /// [center] future first so callers can `await` the most important one.
  Future<void> preloadWindow(
    int center, {
    EQuranFontMode mode = EQuranFontMode.plainV2,
    int radius = 2,
  }) async {
    await loadBasmala();
    await loadPage(center, mode);
    final neighbours = <int>[];
    for (int i = 1; i <= radius; i++) {
      neighbours.addAll([center - i, center + i]);
    }
    await Future.wait(
      neighbours
          .where((p) => p >= 1 && p <= 604)
          .map((p) => loadPage(p, mode)),
    );
  }

  bool isLoaded(int page, [EQuranFontMode mode = EQuranFontMode.plainV2]) =>
      _loadedFamilies.contains(familyFor(page, mode));
}
