import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Color, loadFontFromList;

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/core/services/logging/app_logger.dart';

/// Registers the QPC-V4 colored-tajweed page fonts on demand.
///
/// Each Mushaf page ships as a gzipped COLR/CPAL font
/// (`assets/fonts/qpc_v4/QCF4{NNN}_COLOR-Regular.ttf.gz`). On first use for a
/// page we decompress it once and register four families via [loadFontFromList]
/// — a colored-tajweed pair and a plain (non-tajweed) pair, each in light/dark:
/// - `qcf4_p{page}`   — tajweed, light: the font's own baked colours (black base).
/// - `qcf4_p{page}d`  — tajweed, dark:  base black re-palettized to white, colours kept.
/// - `qcf4_p{page}n`  — plain,   light: every CPAL colour collapsed to black.
/// - `qcf4_p{page}nd` — plain,   dark:  every CPAL colour collapsed to white.
///
/// The `d`/`n`/`nd` variants are CPAL byte-patches ported from the package's
/// `QuranFontsService` (`_modifyCpalBaseColor` / `_modifyCpalAllColors`).
///
/// Families are namespaced (`qcf4_`) so they never collide with the existing
/// QPC-V2 families (`QCF_V2_P{page}`). Fonts cannot be unloaded by Flutter, so
/// this only tracks what has been registered.
class DSQpcV4FontLoader {
  DSQpcV4FontLoader();

  static const int _totalPages = 604;

  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  final Set<int> _loadedPages = <int>{};
  final Map<int, Future<void>> _inFlight = <int, Future<void>>{};

  /// Font family for [page] (1-based) in the given brightness + tajweed mode.
  String familyFor(int page, {required bool dark, required bool tajweed}) {
    final base = 'qcf4_p$page';
    if (tajweed) return dark ? '${base}d' : base;
    return dark ? '${base}nd' : '${base}n';
  }

  /// Whether the families for [page] are registered and ready to paint.
  bool isPageReady(int page) => _loadedPages.contains(page);

  /// Registers the fonts for [page]. No-op if already loaded or in flight.
  Future<void> loadPage(int page) {
    if (page < 1 || page > _totalPages) return Future.value();
    if (_loadedPages.contains(page)) return Future.value();
    final existing = _inFlight[page];
    if (existing != null) return existing;
    final f = _loadInternal(page);
    _inFlight[page] = f;
    return f.whenComplete(() => _inFlight.remove(page));
  }

  /// Registers the visible [center] page (awaited) and warms a small neighbour
  /// window in the background so a swipe lands on a ready font without the
  /// caller waiting on neighbours it may never reach.
  Future<void> preloadWindow(int center, {int radius = 2}) async {
    await loadPage(center);
    for (var i = 1; i <= radius; i++) {
      unawaited(loadPage(center - i));
      unawaited(loadPage(center + i));
    }
  }

  Future<void> _loadInternal(int page) async {
    try {
      final bytes = await _decompress(page);

      // 1) Tajweed light — the font's own colours (black base layer). Critical:
      //    if this fails the page can't render, so it isn't wrapped best-effort.
      await loadFontFromList(
        bytes,
        fontFamily: familyFor(page, dark: false, tajweed: true),
      );

      // 2-4) Variant families via CPAL patches. Best-effort — a patch failure
      //      must not block the page; the tajweed-light family already renders.
      await _registerVariant(page, dark: true, tajweed: true,
          patch: () => _modifyCpalBaseColor(Uint8List.fromList(bytes), _white));
      await _registerVariant(page, dark: false, tajweed: false,
          patch: () => _modifyCpalAllColors(Uint8List.fromList(bytes), _black));
      await _registerVariant(page, dark: true, tajweed: false,
          patch: () => _modifyCpalAllColors(Uint8List.fromList(bytes), _white));

      _loadedPages.add(page);
    } catch (e, st) {
      AppLogger.error('Failed loading QPC-V4 font page $page',
          error: e, stackTrace: st);
    }
  }

  Future<void> _registerVariant(
    int page, {
    required bool dark,
    required bool tajweed,
    required Uint8List Function() patch,
  }) async {
    try {
      await loadFontFromList(
        patch(),
        fontFamily: familyFor(page, dark: dark, tajweed: tajweed),
      );
    } catch (e, st) {
      AppLogger.error(
        'QPC-V4 font variant patch failed for page $page (dark=$dark tajweed=$tajweed)',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<Uint8List> _decompress(int page) async {
    final padded = page.toString().padLeft(3, '0');
    final asset = 'assets/fonts/qpc_v4/QCF4${padded}_COLOR-Regular.ttf.gz';
    final data = await rootBundle.load(asset);
    final gz = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return Uint8List.fromList(const GZipDecoder().decodeBytes(gz));
  }

  // --- CPAL patch (ported from QuranFontsService._modifyCpalBaseColor) -------

  /// Finds the `CPAL` table and replaces the base black colour records (the
  /// Quran text layer) with [newBaseColor]. Tajweed colours (red/green/blue…)
  /// are left untouched. Returns the bytes unmodified if no CPAL table is found.
  Uint8List _modifyCpalBaseColor(Uint8List fontBytes, Color newBaseColor) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C; // 'CPAL'
    for (var t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      if (bd.getUint32(recordOffset) == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (newBaseColor.r * 255).round();
    final newG = (newBaseColor.g * 255).round();
    final newB = (newBaseColor.b * 255).round();
    final newA = (newBaseColor.a * 255).round();

    for (var c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;

      final b = fontBytes[colorOffset];
      final g = fontBytes[colorOffset + 1];
      final r = fontBytes[colorOffset + 2];
      final a = fontBytes[colorOffset + 3];

      // Detect the near-black base colour (RGB ≤ 30, Alpha ≥ 200).
      if (r <= 30 && g <= 30 && b <= 30 && a >= 200) {
        fontBytes[colorOffset] = newB;
        fontBytes[colorOffset + 1] = newG;
        fontBytes[colorOffset + 2] = newR;
        fontBytes[colorOffset + 3] = newA;
      }
    }

    return fontBytes;
  }

  /// Replaces **every** CPAL colour with a single [color] — used to build the
  /// plain (non-tajweed) families where the whole page renders in one colour.
  /// Ported from the package's `QuranFontsService._modifyCpalAllColors`.
  Uint8List _modifyCpalAllColors(Uint8List fontBytes, Color color) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C; // 'CPAL'
    for (var t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      if (bd.getUint32(recordOffset) == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (color.r * 255).round();
    final newG = (color.g * 255).round();
    final newB = (color.b * 255).round();
    final newA = (color.a * 255).round();

    for (var c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;
      fontBytes[colorOffset] = newB;
      fontBytes[colorOffset + 1] = newG;
      fontBytes[colorOffset + 2] = newR;
      fontBytes[colorOffset + 3] = newA;
    }

    return fontBytes;
  }
}
