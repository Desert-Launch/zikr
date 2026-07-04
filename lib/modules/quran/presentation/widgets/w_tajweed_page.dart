import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_rule.dart';
import 'package:quran/modules/quran/domain/entities/e_tajweed_token.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_tajweed_tokens.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/tajweed_palette.dart';
import 'package:quran/modules/quran/presentation/widgets/w_ayah_highlight_text.dart';
import 'package:quran/modules/quran/presentation/widgets/w_basmala_line.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page.dart' show readerBackground;
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';

/// Approach-B Tajweed renderer: paints ayah text ourselves and colours each
/// token from a theme-aware map (light/sepia/dark).
///
/// To stay faithful to the printed Madani page, it lays the coloured text out on
/// the *same QPC line grid* as [WMushafPage] — identical line breaks, per-line
/// fit-to-width sizing, one-screen page, surah header, basmala, and page number.
/// The only thing it can't match is the QPC glyph shape (a colour font can't be
/// themed), so it uses the Amiri Quran text font. See
/// `docs/plans/Tajweed_Approach_B_Plan.md`.
class WTajweedPage extends StatefulWidget {
  const WTajweedPage({required this.layout, super.key});

  final MPageLayout layout;

  @override
  State<WTajweedPage> createState() => _WTajweedPageState();
}

/// One coloured run inside a word.
class _Seg {
  const _Seg(this.text, this.rule);
  final String text;
  final ETajweedRule? rule;
}

class _WTajweedPageState extends State<WTajweedPage> {
  final List<TapGestureRecognizer> _recognizers = [];

  /// Per ayah key (`"surah:ayah"`) → its words, each a list of coloured runs.
  /// `null` until loaded.
  Map<String, List<List<_Seg>>>? _coloured;
  Map<int, MSurah> _surahs = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Load this page's QPC V2 font too — the ayah-end markers reuse the exact
    // rosette glyph the printed Mushaf uses (rendered from QCF_V2_P{page}).
    final fontFut = Modular.get<DSQpcFontLoader>().loadPage(widget.layout.page);
    final surahsList = await Modular.get<DSLocalQuran>().loadSurahs();
    final res = await Modular.get<UCGetTajweedTokens>()(widget.layout.page);
    await fontFut;
    if (!mounted) return;
    final map = res.fold(
      (_) => const <String, List<ETajweedToken>>{},
      (m) => m,
    );
    setState(() {
      _surahs = {for (final s in surahsList) s.number: s};
      _coloured = {
        for (final entry in map.entries) entry.key: _splitWords(entry.value),
      };
    });
  }

  /// Splits an ayah's token stream into words (on spaces), keeping each word's
  /// coloured runs. A space lives inside an uncoloured token, so it both ends a
  /// word and is dropped.
  static List<List<_Seg>> _splitWords(List<ETajweedToken> tokens) {
    final words = <List<_Seg>>[];
    var current = <_Seg>[];
    for (final tok in tokens) {
      final parts = tok.text.split(' ');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0 && current.isNotEmpty) {
          words.add(current);
          current = <_Seg>[];
        }
        if (parts[i].isNotEmpty) current.add(_Seg(parts[i], tok.rule));
      }
    }
    if (current.isNotEmpty) words.add(current);
    return words;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recogniser(ParamAyahRef ref, CBMushafReader cubit) {
    final r = TapGestureRecognizer()..onTap = () => cubit.selectAyah(ref);
    _recognizers.add(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBMushafReader>(context);
    final coloured = _coloured;

    return BlocSelector<
      CBMushafReader,
      SMushafReader,
      ({ParamAyahRef? selected, double scale, ReaderTheme theme, Map<String, String?> bookmarks})
    >(
      selector: (s) => (
        selected: s.selectedAyah,
        scale: s.fontScale,
        theme: s.theme,
        bookmarks: s.bookmarks,
      ),
      builder: (context, view) {
        final background = readerBackground(view.theme, colored: false);
        if (coloured == null) {
          return ColoredBox(color: background); // tokens load fast — no spinner
        }
        final brightness = tajweedBrightness(view.theme);
        final baseColour = tajweedBaseColour(brightness: brightness);
        final headerDark = view.theme == ReaderTheme.dark;

        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            // Rebuild recognizers fresh each pass so stale callbacks never leak.
            for (final r in _recognizers) {
              r.dispose();
            }
            _recognizers.clear();

            final pageNumber = Center(
              child: Text(
                '${widget.layout.page}',
                style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
              ),
            );
            final pageHeader = WMushafPageHeader(
              surahName: _pageSurahName,
              page: widget.layout.page,
              color: headerDark ? Colors.white70 : context.brand.muted,
            );

            // Above printed size the page reflows into one justified, vertically
            // scrollable block — same behaviour as the QPC renderer.
            final reflow = view.scale > 1.0;
            if (reflow) {
              final children = <Widget>[];
              final paragraph = <InlineSpan>[];
              void flush() {
                if (paragraph.isEmpty) return;
                children.add(
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: RichText(
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(children: List<InlineSpan>.of(paragraph)),
                    ),
                  ),
                );
                paragraph.clear();
              }

              for (final line in widget.layout.lines) {
                switch (line.type) {
                  case LineType.surahHeader:
                    flush();
                    children.add(_surahHeader(line, dark: headerDark));
                    break;
                  case LineType.basmala:
                    flush();
                    children.add(
                      WBasmalaLine(fontSize: 28.sp * view.scale, color: baseColour),
                    );
                    break;
                  case LineType.spacer:
                    flush();
                    children.add(SizedBox(height: 8.h));
                    break;
                  case LineType.text:
                    if (paragraph.isNotEmpty) {
                      paragraph.add(const TextSpan(text: ' '));
                    }
                    paragraph.addAll(
                      _lineSpans(
                        line,
                        cubit: cubit,
                        coloured: coloured,
                        selected: view.selected,
                        playing: playing,
                        bookmarks: view.bookmarks,
                        scale: view.scale,
                        baseColour: baseColour,
                        brightness: brightness,
                        fontSize: 28.sp * view.scale,
                        height: 1.9,
                      ),
                    );
                    break;
                }
              }
              flush();

              return Container(
                color: background,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      pageHeader,
                      ...children,
                      SizedBox(height: 8.h),
                      pageNumber,
                    ],
                  ),
                ),
              );
            }

            // Exact mode: one screen. Unlike QPC glyph lines (pre-justified to a
            // uniform width by the font), real text lines vary in length, so a
            // per-line fit would size every page differently. Instead we pick a
            // single font size — driven by the densest line in the whole Mushaf —
            // and use it on every page, so text is the same size throughout.
            return LayoutBuilder(
              builder: (context, constraints) {
                final avail = constraints.maxWidth - 24.w;
                final fontSize = _uniformFontSize(context, avail, view.scale);

                final wrappedLines = widget.layout.lines.map<Widget>((line) {
                  switch (line.type) {
                    case LineType.surahHeader:
                      return _surahHeader(line, dark: headerDark);
                    case LineType.basmala:
                      // Size the basmala to a fixed share of the page width: the
                      // uniform body font size leaves it small and a plain
                      // scale-down only ever shrinks it further. BoxFit.contain
                      // inside a fixed-width box gives a large, consistent
                      // centered basmala on every surah-opening page.
                      return Center(
                        child: SizedBox(
                          width: avail * 0.5,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            child: WBasmalaLine(fontSize: fontSize, color: baseColour),
                          ),
                        ),
                      );
                    case LineType.spacer:
                      return SizedBox(height: 8.h);
                    case LineType.text:
                      return _justifiedTextLine(
                        line,
                        context: context,
                        avail: avail,
                        fontSize: fontSize,
                        cubit: cubit,
                        coloured: coloured,
                        selected: view.selected,
                        playing: playing,
                        bookmarks: view.bookmarks,
                        scale: view.scale,
                        baseColour: baseColour,
                        brightness: brightness,
                      );
                  }
                }).toList(growable: false);

                // Mirror the QPC renderer's vertical rhythm: dense pages fill the
                // height with even leading; short opening pages (Fatihah, surah
                // starts) stay a compact centered block rather than spreading.
                final isFullPage = widget.layout.lines.length >= 12;

                return Container(
                  color: background,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      pageHeader,
                      Expanded(
                        child: Column(
                          mainAxisAlignment: isFullPage
                              ? MainAxisAlignment.spaceEvenly
                              : MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: wrappedLines,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      pageNumber,
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Arabic short name of the surah at the top of the page (running head).
  String get _pageSurahName {
    final refs = widget.layout.allAyahRefs;
    if (refs.isEmpty) return '';
    final surah = _surahs[refs.first.surah];
    if (surah == null) return '';
    return surah.arabic.isNotEmpty ? surah.arabic : surah.arabicLong;
  }

  WSurahHeader _surahHeader(MLine line, {required bool dark}) {
    final surah = _surahs[line.surahNumber];
    return WSurahHeader(
      title: line.text.isNotEmpty
          ? line.text
          : (surah?.arabicLong.isNotEmpty ?? false
                ? surah?.arabicLong ?? ''
                : surah?.arabic ?? ''),
      surahNumber: surah?.number ?? line.surahNumber,
      ayahCount: surah?.totalAyah,
      dark: dark,
      tajweed: true,
    );
  }

  /// Coloured spans for one QPC [line]: each QPC word maps to its aligned
  /// tajweed-coloured runs; the ayah's selection/playback/bookmark tint and tap
  /// recognizer are shared across its words; ayah-number glyphs become badges.
  List<InlineSpan> _lineSpans(
    MLine line, {
    required CBMushafReader cubit,
    required Map<String, List<List<_Seg>>> coloured,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required double scale,
    required Color baseColour,
    required Brightness brightness,
    required double fontSize,
    required double height,
    // Exact mode passes this: selection/playback/bookmark tints are collected as
    // character ranges and painted behind the text by [WAyahHighlightText] so the
    // highlight grows taller without inflating line height. When null (reflow),
    // the tint is a line-box backgroundColor as before.
    List<AyahHighlight>? highlightsOut,
  }) {
    final spans = <InlineSpan>[];
    final paintBg = highlightsOut == null;
    var offset = 0;
    // Per ayah key → the contiguous char range its words occupy in this line.
    final hlStart = <String, int>{};
    final hlEnd = <String, int>{};
    final hlColor = <String, Color>{};

    void add(InlineSpan span, {String? hlKey, Color? tint}) {
      spans.add(span);
      final len = span is WidgetSpan ? 1 : ((span as TextSpan).text?.length ?? 0);
      if (highlightsOut != null && hlKey != null && tint != null) {
        hlStart.putIfAbsent(hlKey, () => offset);
        hlEnd[hlKey] = offset + len;
        hlColor[hlKey] = tint;
      }
      offset += len;
    }

    for (int wi = 0; wi < line.words.length; wi++) {
      final w = line.words[wi];
      final ref = ParamAyahRef(surah: w.surah, ayah: w.ayah);
      final tint = _tintFor(ref, selected, playing, bookmarks, brightness);
      final recognizer = _recogniser(ref, cubit);

      TextStyle styleFor(Color colour) => TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: fontSize,
        height: height,
        color: colour,
        backgroundColor: paintBg ? tint : null,
      );

      final word = coloured[ref.key];
      final idx = _wordIndex(w.location);
      final segs = (word != null && idx >= 0 && idx < word.length) ? word[idx] : null;

      if (segs == null) {
        // Fallback (e.g. the single word-segmentation outlier, 37:130): render
        // the QPC word's own text, uncoloured, so nothing is ever dropped.
        add(
          TextSpan(text: _stripNumber(w.word), recognizer: recognizer, style: styleFor(baseColour)),
          hlKey: ref.key,
          tint: tint,
        );
      } else {
        for (final s in segs) {
          add(
            TextSpan(
              text: s.text,
              recognizer: recognizer,
              style: styleFor(s.rule == null ? baseColour : tajweedColour(s.rule!, brightness: brightness)),
            ),
            hlKey: ref.key,
            tint: tint,
          );
        }
      }

      // The QPC word carrying the ayah number marks the ayah end → render the
      // exact QPC rosette glyph (the last glyph of the word's V2 code), so the
      // marker is identical to the printed Mushaf. Fall back to a drawn badge
      // only if the glyph is somehow missing.
      if (_hasArabicDigit(w.word)) {
        final v2 = w.qpcV2;
        final endGlyph = (v2 != null && v2.isNotEmpty) ? v2.split(' ').last : '';
        if (endGlyph.isNotEmpty) {
          add(const TextSpan(text: ' '), hlKey: ref.key, tint: tint);
          add(
            TextSpan(
              text: endGlyph,
              recognizer: recognizer,
              style: TextStyle(
                fontFamily: DSQpcFontLoader.pageFamily(widget.layout.page),
                fontSize: fontSize,
                height: height,
                color: baseColour,
                backgroundColor: paintBg ? tint : null,
              ),
            ),
            hlKey: ref.key,
            tint: tint,
          );
        } else {
          add(
            _ayahEndBadge(ref, cubit, scale: scale, brightness: brightness, tint: tint),
            hlKey: ref.key,
            tint: tint,
          );
        }
      }
      if (wi != line.words.length - 1) {
        // Keep the pill continuous across words of the SAME ayah by tagging the
        // separating space; a boundary space between two ayat stays untagged.
        final next = line.words[wi + 1];
        final sameNext = next.surah == w.surah && next.ayah == w.ayah;
        add(const TextSpan(text: ' '), hlKey: sameNext ? ref.key : null, tint: sameNext ? tint : null);
      }
    }

    if (highlightsOut != null) {
      for (final key in hlStart.keys) {
        highlightsOut.add(AyahHighlight(start: hlStart[key] ?? 0, end: hlEnd[key] ?? 0, color: hlColor[key] ?? baseColour));
      }
    }
    return spans;
  }

  /// One printed line, justified to fill the page width like the printed Mushaf.
  ///
  /// Amiri text — unlike the QPC glyph lines, which the per-page font pre-spaces
  /// to a uniform width — doesn't reach both edges on its own, so it renders
  /// centered with margins. Here we measure the line's natural width and spread
  /// the slack across its inter-word spaces via [TextStyle.wordSpacing], so the
  /// line fills the page without distorting letter shapes. Genuinely short lines
  /// (surah ends) stay centered — stretching them would leave ugly gaps — and
  /// the rare over-wide line scales down to fit, both matching the printed page.
  Widget _justifiedTextLine(
    MLine line, {
    required BuildContext context,
    required double avail,
    required double fontSize,
    required CBMushafReader cubit,
    required Map<String, List<List<_Seg>>> coloured,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required double scale,
    required Color baseColour,
    required Brightness brightness,
  }) {
    final highlights = <AyahHighlight>[];
    final spans = _lineSpans(
      line,
      cubit: cubit,
      coloured: coloured,
      selected: selected,
      playing: playing,
      bookmarks: bookmarks,
      scale: scale,
      baseColour: baseColour,
      brightness: brightness,
      fontSize: fontSize,
      height: 1.0,
      highlightsOut: highlights,
    );

    final rootStyle = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: fontSize,
      height: 1.0,
    );

    // Grow the selection pill above/below the glyphs without touching leading.
    final pad = fontSize * 0.36;

    // The ayah-end badge fallback is a WidgetSpan the painter can't measure;
    // such (rare) lines keep the plain centered/scale-down path.
    final hasWidgetSpan = spans.any((s) => s is WidgetSpan);
    final spaceCount =
        spans.where((s) => s is TextSpan && s.text == ' ').length;

    // Pages 1–2 (Al-Fatihah and the opening of Al-Baqarah) are the Mushaf's
    // decorative opening spread: a compact centered block, never justified to
    // the page edges — so they keep the centered fallback path below.
    final isOpeningSpread = widget.layout.page <= 2;

    if (!isOpeningSpread && !hasWidgetSpan && spaceCount > 0) {
      final tp = TextPainter(
        text: TextSpan(style: rootStyle, children: spans),
        textDirection: TextDirection.rtl,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final natural = tp.width;
      // Stretch only near-full lines to the edges; below this the line is a
      // genuine short line (surah end) better left centered. Threshold is
      // deliberately conservative and easy to tune.
      if (natural <= avail && natural >= avail * 0.6) {
        final wordSpacing = (avail - natural) / spaceCount;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: SizedBox(
            width: avail,
            child: WAyahHighlightText(
              text: TextSpan(style: rootStyle.copyWith(wordSpacing: wordSpacing), children: spans),
              ranges: highlights,
              pad: pad,
              maxWidth: avail,
            ),
          ),
        );
      }
    }

    // Fallback: center short lines, scale down the rare over-wide line.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: WAyahHighlightText(
          text: TextSpan(style: rootStyle, children: spans),
          ranges: highlights,
          pad: pad,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color? _tintFor(
    ParamAyahRef ref,
    ParamAyahRef? selected,
    ParamAyahRef? playing,
    Map<String, String?> bookmarks,
    Brightness brightness,
  ) {
    if (selected?.key == ref.key) {
      // The solid green reads fine on cream, but on the dark page it buries the
      // text, so drop it to a low-opacity tint there.
      return brightness == Brightness.dark
          ? AppColors.surfaceLightGreen.withValues(alpha: 0.22)
          : AppColors.surfaceLightGreen;
    }
    if (playing?.key == ref.key) {
      return AppColors.accentGoldAmber.withValues(alpha: 0.15);
    }
    if (bookmarks.containsKey(ref.key)) {
      return bookmarkHighlightFromHex(bookmarks[ref.key]);
    }
    return null;
  }

  /// A themed circular ayah-number badge (we own it — no QPC end-glyph).
  WidgetSpan _ayahEndBadge(
    ParamAyahRef ref,
    CBMushafReader cubit, {
    required double scale,
    required Brightness brightness,
    required Color? tint,
  }) {
    final dark = brightness == Brightness.dark;
    final line = dark ? Colors.white70 : const Color(0xFF0A7A4F);
    final size = 24.sp * scale;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => cubit.selectAyah(ref),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1.1),
            ),
            child: Text(
              _arabicNumber(ref.ayah),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 10.sp * scale,
                color: line,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A representative *dense* Mushaf line (~p85 length, diacritics kept, tatweel
  /// removed). Used as the width yard-stick so every page is typeset at the same
  /// size: the size at which this line just fits the page width. The handful of
  /// longer-than-this lines are nudged down by the per-line FittedBox safety,
  /// which keeps the bulk of the text larger and uniform across pages.
  static const String _refDenseLine =
      'ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ تَبَٰرَكَ ٱسْمُ رَبِّكَ ذِى ٱلْجَلَٰلِ وَٱلْإِكْرَامِ';

  double _uniformFontSize(BuildContext context, double avail, double scale) {
    final base = 28.sp * scale;
    if (avail <= 0) return base;
    final tp = TextPainter(
      text: TextSpan(
        text: _refDenseLine,
        style: TextStyle(fontFamily: 'AmiriQuran', fontSize: base, height: 1.0),
      ),
      textDirection: TextDirection.rtl,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final w = tp.width;
    if (w <= 0 || w <= avail) return base;
    return base * (avail / w);
  }

  static int _wordIndex(String location) {
    final parts = location.split(':');
    if (parts.length < 3) return -1;
    return (int.tryParse(parts[2]) ?? 0) - 1;
  }

  static bool _hasArabicDigit(String s) =>
      s.runes.any((c) => (c >= 0x0660 && c <= 0x0669) || (c >= 0x06F0 && c <= 0x06F9));

  static String _stripNumber(String s) {
    final buf = StringBuffer();
    for (final c in s.runes) {
      if ((c >= 0x0660 && c <= 0x0669) || (c >= 0x06F0 && c <= 0x06F9)) continue;
      buf.writeCharCode(c);
    }
    return buf.toString().trim();
  }

  static String _arabicNumber(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }
}
