import 'dart:async';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';

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
  static String pageFamily(int page) => 'QCF_P$page';

  final Set<int> _loadedPages = <int>{};
  bool _basmalaLoaded = false;
  final Map<int, Future<void>> _inFlight = {};

  /// Returns once the font for [page] is registered. Subsequent calls are no-ops.
  Future<void> loadPage(int page) {
    if (page < 1 || page > 604) return Future.value();
    if (_loadedPages.contains(page)) return Future.value();
    final existing = _inFlight[page];
    if (existing != null) return existing;
    final f = _loadFontInternal(page);
    _inFlight[page] = f;
    return f.whenComplete(() => _inFlight.remove(page));
  }

  Future<void> _loadFontInternal(int page) async {
    try {
      final padded = page.toString().padLeft(3, '0');
      final asset = 'assets/fonts/qpc/QCF_P$padded.TTF';
      final family = pageFamily(page);
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(asset));
      await loader.load();
      _loadedPages.add(page);

      // Best-effort: bookkeep how many we've loaded. We don't have an unload API
      // in Flutter for runtime-registered fonts, so the bound is informational.
      if (_loadedPages.length > _maxLoadedPages) {
        final oldest = _loadedPages.first;
        _loadedPages.remove(oldest);
      }
    } catch (e, st) {
      AppLogger.error('Failed loading QPC page font $page', error: e, stackTrace: st);
    }
  }

  Future<void> loadBasmala() async {
    if (_basmalaLoaded) return;
    try {
      final loader = FontLoader(basmalaFamily);
      loader.addFont(rootBundle.load('assets/fonts/qpc/QCF_BSML.TTF'));
      await loader.load();
      _basmalaLoaded = true;
    } catch (e, st) {
      AppLogger.error('Failed loading QCF_BSML', error: e, stackTrace: st);
    }
  }

  /// Preload the visible page + a window of neighbours. Returns the [center]
  /// future first so callers can `await` the most important one synchronously.
  Future<void> preloadWindow(int center, {int radius = 2}) async {
    await loadBasmala();
    await loadPage(center);
    final neighbours = <int>[];
    for (int i = 1; i <= radius; i++) {
      neighbours.addAll([center - i, center + i]);
    }
    await Future.wait(neighbours.where((p) => p >= 1 && p <= 604).map(loadPage));
  }

  bool isLoaded(int page) => _loadedPages.contains(page);
}
