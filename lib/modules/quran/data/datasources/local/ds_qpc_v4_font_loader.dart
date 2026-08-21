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
/// 2. **Only the variant actually being rendered is awaited.** The other three
///    are registered afterwards, one page at a time, through [_enqueue] — so a
///    page costs one `loadFontFromList` on the critical path instead of four,
///    and a theme or tajweed toggle still finds its family already there.
class DSQpcV4FontLoader {
  DSQpcV4FontLoader();

  static const int _totalPages = 604;

  /// Families registered so far, per page. A page is only renderable in the
  /// variant whose family is in its set — see [isPageReady].
  final Map<int, Set<String>> _registered = <int, Set<String>>{};

  /// One in-flight [_loadInternal] per page, so a page swiped across twice does
  /// not decompress twice.
  final Map<int, Future<void>> _inFlight = <int, Future<void>>{};

  /// Serialises the background work — neighbour warmups and the three
  /// off-screen variants — into a single chain. Without it a fast scroll fans
  /// out a dozen concurrent isolates and font registrations, which is slower
  /// than doing them one at a time and far jerkier.
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

  /// Registers the fonts for [page], resolving as soon as the variant named by
  /// [dark] / [tajweed] can be painted. The remaining three are registered in
  /// the background afterwards.
  Future<void> loadPage(
    int page, {
    required bool dark,
    required bool tajweed,
  }) {
    if (page < 1 || page > _totalPages) return Future<void>.value();
    if (isPageReady(page, dark: dark, tajweed: tajweed)) {
      return Future<void>.value();
    }
    final existing = _inFlight[page];
    if (existing != null) return existing;
    final f = _loadInternal(page, dark: dark, tajweed: tajweed);
    _inFlight[page] = f;
    return f.whenComplete(() => _inFlight.remove(page));
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
      // Ungzip + the three CPAL patches, off the UI isolate. What comes back is
      // four ready-to-register TTF byte arrays in [_QpcVariant] order.
      final variants = await compute(_decodeAndPatch, gz);

      // The variant on screen goes first and is the only one this future waits
      // on — the page can paint the moment it lands.
      final wanted = _variantIndex(dark: dark, tajweed: tajweed);
      await _register(page, wanted, variants[wanted]);

      // The other three ride the background chain. They are what makes a theme
      // or tajweed toggle instant later on, but nothing on screen needs them
      // now.
      final pending = <int, Uint8List>{
        for (var i = 0; i < variants.length; i++)
          if (i != wanted) i: variants[i],
      };
      _enqueue(() async {
        for (final entry in pending.entries) {
          await _register(page, entry.key, entry.value);
        }
      });
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
// The four families are addressed by index so the isolate can return them as a
// plain list. Order is fixed and shared with [_decodeAndPatch].

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

/// Ungzips one page font and produces all four CPAL variants of it.
///
/// Top-level and pure so it can run under [compute]: it touches no engine API,
/// only bytes. Returns the four TTFs in `_kTajweedLight … _kPlainDark` order.
List<Uint8List> _decodeAndPatch(Uint8List gzBytes) {
  final base = Uint8List.fromList(const GZipDecoder().decodeBytes(gzBytes));
  return <Uint8List>[
    // Tajweed light is the font exactly as shipped — black base layer, the
    // font's own tajweed colours.
    base,
    _modifyCpalBaseColor(Uint8List.fromList(base), _kWhite),
    _modifyCpalAllColors(Uint8List.fromList(base), _kBlack),
    _modifyCpalAllColors(Uint8List.fromList(base), _kWhite),
  ];
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
