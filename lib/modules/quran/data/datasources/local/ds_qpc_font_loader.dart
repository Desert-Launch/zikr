import 'dart:async';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';

/// Registers per-page QPC V1 TTF fonts on demand.
///
/// Strategy:
/// - Each page N uses font family `QCF_P{N}` (loaded from `assets/fonts/qpc/QCF_P{NNN}.TTF`).
/// - Surah headers + basmala use family `QCF_BSML` (loaded from `QCF_BSML.TTF`).
/// - The loader maintains a window of recently-used fonts. Anything past
///   [_maxLoadedPages] entries is left in memory until the OS evicts it
///   (Flutter cannot unload a registered `FontLoader`).
class DSQpcFontLoader {
  DSQpcFontLoader();

  static const int _maxLoadedPages = 9; // current ± 4
  static const String basmalaFamily = 'QCF_BSML';

  /// V1 per-page family (kept for callers that always render V1, e.g. basmala).
  static String pageFamily(int page) => 'QCF_P$page';

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
  Future<void> loadPage(int page, [EQuranFontMode mode = EQuranFontMode.plainV1]) {
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
  /// QCF_BSML.TTF is intentionally NOT used — its cmap is missing the
  /// `U+0670` (superscript alef) glyph, which renders the standard basmala
  /// text as tofu boxes. Instead, every basmala line is drawn using
  /// Al-Fatihah's basmala glyphs (`ﭑ ﭒ ﭓ ﭔ`) and the page-1 font, which
  /// always exists in any QPC V1 set.
  Future<void> loadBasmala() async {
    if (_basmalaLoaded) return;
    await loadPage(1);
    _basmalaLoaded = true;
  }

  /// Preload the visible page + a window of neighbours for [mode]. Returns the
  /// [center] future first so callers can `await` the most important one.
  Future<void> preloadWindow(
    int center, {
    EQuranFontMode mode = EQuranFontMode.plainV1,
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

  bool isLoaded(int page, [EQuranFontMode mode = EQuranFontMode.plainV1]) =>
      _loadedFamilies.contains(familyFor(page, mode));
}
