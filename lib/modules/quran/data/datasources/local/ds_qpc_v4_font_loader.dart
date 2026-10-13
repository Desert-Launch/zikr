import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Color, loadFontFromList;

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/core/services/logging/app_logger.dart';

/// Registers the QPC-V4 colored-tajweed page fonts on demand.
///
/// Each Mushaf page ships as a gzipped COLR/CPAL font
/// (`assets/fonts/qpc_v4/QCF4{NNN}_COLOR-Regular.ttf.gz`). A page can be drawn
/// in four families — a colored-tajweed pair and a plain (non-tajweed) pair,
/// each in light/dark — and each is registered via [loadFontFromList] only
/// when something asks to paint with it:
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
/// this only tracks what has been registered — which is why this is an
/// app-wide singleton: a per-visit instance forgot what it had registered and
/// registered every page again on the next visit.
///
/// It is also why only the variant in use is registered. All four per page
/// cost ~1 MB of native memory for every page read, for the life of the
/// process; the rest of a page's variants are decoded if the reader switches
/// theme or tajweed (a short spinner on the visible pages, once).
///
/// ## Why this is shaped for the scroll loop
///
/// Reading through the Mushaf registers a *new* font every page, and every
/// logical millisecond spent doing it lands on the frame the reader is
/// watching. Two things keep it off that frame:
///
/// 1. **Decompression and the CPAL patches run in a background isolate**
///    ([compute]). Ungzipping ~1 MB and walking its colour records three times
///    is pure byte work with no engine calls, so there is no reason for it to
///    sit on the UI isolate — and it was previously the single largest stall in
///    a fast scroll.
/// 2. **Only the variant actually being rendered is decoded and registered**,
///    so a page costs one `loadFontFromList` instead of four.
class DSQpcV4FontLoader {
  DSQpcV4FontLoader();

  static const int _totalPages = 604;

  /// Families registered so far, per page. A page is only renderable in the
  /// variant whose family is in its set — see [isPageReady].
  final Map<int, Set<String>> _registered = <int, Set<String>>{};

  /// One in-flight [_loadInternal] per family, so a page swiped across twice
  /// does not decompress twice.
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  /// Serialises the neighbour warmups into a single chain. Without it a fast
  /// scroll fans out a dozen concurrent isolates and font registrations, which
  /// is slower than doing them one at a time and far jerkier.
  Future<void> _queue = Future<void>.value();

  /// Font family for [page] (1-based) in the given brightness + tajweed mode.
  String familyFor(int page, {required bool dark, required bool tajweed}) {
    final base = 'qcf4_p$page';
    if (tajweed) return dark ? '${base}d' : base;
    return dark ? '${base}nd' : '${base}n';
  }

  /// Whether the family [page] would be painted with in this mode is registered
  /// and ready.
  bool isPageReady(int page, {required bool dark, required bool tajweed}) =>
      _registered[page]?.contains(
        familyFor(page, dark: dark, tajweed: tajweed),
      ) ??
      false;

  /// Registers the variant of [page] named by [dark] / [tajweed], resolving once
  /// it can be painted.
  Future<void> loadPage(
    int page, {
    required bool dark,
    required bool tajweed,
  }) {
    if (page < 1 || page > _totalPages) return Future<void>.value();
    if (isPageReady(page, dark: dark, tajweed: tajweed)) {
      return Future<void>.value();
    }
    final family = familyFor(page, dark: dark, tajweed: tajweed);
    final existing = _inFlight[family];
    if (existing != null) return existing;
    final f = _loadInternal(page, dark: dark, tajweed: tajweed);
    _inFlight[family] = f;
    return f.whenComplete(() => _inFlight.remove(family));
  }

  /// Registers the visible [center] page (awaited) and warms a small neighbour
  /// window in the background so a swipe lands on a ready font without the
  /// caller waiting on neighbours it may never reach.
  ///
  /// The neighbours are warmed **sequentially**, behind the shared [_queue]:
  /// four pages fanned out at once is four isolates and sixteen font
  /// registrations competing with the page the reader is looking at.
  Future<void> preloadWindow(
    int center, {
    int radius = 2,
    required bool dark,
    required bool tajweed,
  }) async {
    await loadPage(center, dark: dark, tajweed: tajweed);
    final neighbours = <int>[];
    for (var i = 1; i <= radius; i++) {
      neighbours.addAll([center - i, center + i]);
    }
    _enqueue(() async {
      for (final page in neighbours) {
        if (page < 1 || page > _totalPages) continue;
        if (isPageReady(page, dark: dark, tajweed: tajweed)) continue;
        await loadPage(page, dark: dark, tajweed: tajweed);
      }
    });
  }

  /// Appends [task] to the background chain, swallowing failures so one bad
  /// page cannot stall every warmup behind it.
  void _enqueue(Future<void> Function() task) {
    _queue = _queue.then((_) => task()).catchError((Object e, StackTrace st) {
      AppLogger.error('QPC-V4 font warmup failed', error: e, stackTrace: st);
    });
  }

  Future<void> _loadInternal(
    int page, {
    required bool dark,
    required bool tajweed,
  }) async {
    try {
      final gz = await _readAsset(page);
      final variant = _variantIndex(dark: dark, tajweed: tajweed);
      // Ungzip + this variant's CPAL patch, off the UI isolate.
      final bytes = await compute(_decodeVariant, (gz: gz, variant: variant));
      await _register(page, variant, bytes);
    } catch (e, st) {
      AppLogger.error(
        'Failed loading QPC-V4 font page $page',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Registers one variant's bytes under its family name and records it as
  /// ready. Best-effort: a variant that fails to register simply stays absent,
  /// and the renderer keeps whichever ones did land.
  Future<void> _register(int page, int variant, Uint8List bytes) async {
    final family = familyFor(
      page,
      dark: _variantIsDark(variant),
      tajweed: _variantIsTajweed(variant),
    );
    if (_registered[page]?.contains(family) ?? false) return;
    try {
      await loadFontFromList(bytes, fontFamily: family);
      (_registered[page] ??= <String>{}).add(family);
    } catch (e, st) {
      AppLogger.error(
        'QPC-V4 font variant registration failed for page $page ($family)',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<Uint8List> _readAsset(int page) async {
    final padded = page.toString().padLeft(3, '0');
    final asset = 'assets/fonts/qpc_v4/QCF4${padded}_COLOR-Regular.ttf.gz';
    final data = await rootBundle.load(asset);
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}

// --- Variant indexing ------------------------------------------------------
//
// The four families are addressed by index so a variant can be named across
// the isolate boundary — see [_decodeVariant].

const int _kTajweedLight = 0;
const int _kTajweedDark = 1;
const int _kPlainLight = 2;
const int _kPlainDark = 3;

int _variantIndex({required bool dark, required bool tajweed}) {
  if (tajweed) return dark ? _kTajweedDark : _kTajweedLight;
  return dark ? _kPlainDark : _kPlainLight;
}

bool _variantIsDark(int variant) =>
    variant == _kTajweedDark || variant == _kPlainDark;

bool _variantIsTajweed(int variant) =>
    variant == _kTajweedLight || variant == _kTajweedDark;

// --- Background isolate work ----------------------------------------------

/// Ungzips one page font and produces the requested CPAL variant of it.
///
/// Top-level and pure so it can run under [compute]: it touches no engine API,
/// only bytes.
Uint8List _decodeVariant(({Uint8List gz, int variant}) job) {
  final base = Uint8List.fromList(const GZipDecoder().decodeBytes(job.gz));
  return switch (job.variant) {
    _kTajweedDark => _modifyCpalBaseColor(base, _kWhite),
    _kPlainLight => _modifyCpalAllColors(base, _kBlack),
    _kPlainDark => _modifyCpalAllColors(base, _kWhite),
    // Tajweed light is the font exactly as shipped — black base layer, the
    // font's own tajweed colours.
    _ => base,
  };
}

const Color _kWhite = Color(0xFFFFFFFF);
const Color _kBlack = Color(0xFF000000);

/// Offset and length of the font's `CPAL` table, or `null` when it has none.
({int offset, int length})? _findCpal(Uint8List fontBytes) {
  if (fontBytes.length < 12) return null;
  final bd = ByteData.view(
    fontBytes.buffer,
    fontBytes.offsetInBytes,
    fontBytes.lengthInBytes,
  );
  final numTables = bd.getUint16(4);
  const cpalTag = 0x4350414C; // 'CPAL'
  for (var t = 0; t < numTables; t++) {
    final recordOffset = 12 + t * 16;
    if (recordOffset + 16 > fontBytes.length) break;
    if (bd.getUint32(recordOffset) == cpalTag) {
      final offset = bd.getUint32(recordOffset + 8);
      final length = bd.getUint32(recordOffset + 12);
      if (offset + length > fontBytes.length) return null;
      if (offset + 12 > fontBytes.length) return null;
      return (offset: offset, length: length);
    }
  }
  return null;
}

/// Finds the `CPAL` table and replaces the base black colour records (the
/// Quran text layer) with [newBaseColor]. Tajweed colours (red/green/blue…)
/// are left untouched. Returns the bytes unmodified if no CPAL table is found.
Uint8List _modifyCpalBaseColor(Uint8List fontBytes, Color newBaseColor) {
  final cpal = _findCpal(fontBytes);
  if (cpal == null) return fontBytes;
  final bd = ByteData.view(
    fontBytes.buffer,
    fontBytes.offsetInBytes,
    fontBytes.lengthInBytes,
  );

  final numColorRecords = bd.getUint16(cpal.offset + 6);
  final absColorRecordsOffset = cpal.offset + bd.getUint32(cpal.offset + 8);

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
  final cpal = _findCpal(fontBytes);
  if (cpal == null) return fontBytes;
  final bd = ByteData.view(
    fontBytes.buffer,
    fontBytes.offsetInBytes,
    fontBytes.lengthInBytes,
  );

  final numColorRecords = bd.getUint16(cpal.offset + 6);
  final absColorRecordsOffset = cpal.offset + bd.getUint32(cpal.offset + 8);

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
