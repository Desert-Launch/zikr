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
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_basmala_line.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_tajweed_page.dart';

/// Renders one Mushaf page from its [MPageLayout].
///
/// Each line of `LineType.text` is a single [RichText] composed of QPC glyphs,
/// grouped by ayah. The ayah groups share a [TapGestureRecognizer] so tapping
/// any word in an ayah selects the whole ayah.
class WMushafPage extends StatefulWidget {
  const WMushafPage({required this.layout, super.key});

  final MPageLayout layout;

  @override
  State<WMushafPage> createState() => _WMushafPageState();
}

class _WMushafPageState extends State<WMushafPage> {
  final List<TapGestureRecognizer> _recognizers = [];
  late final DSQpcFontLoader _fonts = Modular.get<DSQpcFontLoader>();
  Map<int, MSurah> _surahs = const {};

  @override
  void initState() {
    super.initState();
    // Tajweed renders via WTajweedPage (static Amiri font) — no QPC glyph
    // fonts to preload for that mode.
    final mode = Modular.get<CBReaderSettings>().state.fontMode;
    if (mode != EQuranFontMode.tajweedV4) {
      _fonts.preloadWindow(widget.layout.page, mode: mode);
    }
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await Modular.get<DSLocalQuran>().loadSurahs();
    if (!mounted) return;
    setState(() {
      _surahs = {for (final surah in surahs) surah.number: surah};
    });
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

    return BlocSelector<
      CBMushafReader,
      SMushafReader,
      ({ParamAyahRef? selected, double scale, ReaderTheme theme, EQuranFontMode mode, Map<String, String?> bookmarks})
    >(
      selector: (s) =>
          (selected: s.selectedAyah, scale: s.fontScale, theme: s.theme, mode: s.fontMode, bookmarks: s.bookmarks),
      builder: (context, view) {
        // Tajweed (Approach B): a separate text renderer that colours each
        // token itself from a theme-aware map, laid out on this same QPC line
        // grid — not the QPC glyph path below.
        if (view.mode == EQuranFontMode.tajweedV4) {
          return WTajweedPage(layout: widget.layout);
        }
        final fontFamily = view.mode.fontFamilyForPage(widget.layout.page);
        final isColored = view.mode.isColored;
        // Pages 1–2 (Al-Fatihah + the opening of Al-Baqarah) hold only a few
        // short, sparsely-packed lines, so the shared base size looks oversized
        // there; every other page packs longer lines that read a touch small.
        // Nudge the base size per page: gently down on the openers, up elsewhere.
        final pageScale = widget.layout.page <= 2 ? 0.8 : 1;
        // QPC V1 glyphs have hair-thin strokes by design — keep the text in a
        // saturated near-black so they remain readable over the cream paper.
        // Theme.onSurface (#1A1A1A) is technically dark but loses contrast on
        // cream once anti-aliasing thins the strokes further. In dark theme the
        // base text flips to white — but NOT for V4: its base letters are
        // baked black in the font palette (uncolourable), so tajweed stays on a
        // light page (see [readerBackground]) and keeps dark text.
        final fg = (view.theme == ReaderTheme.dark && !isColored) ? Colors.white : const Color(0xFF0A0A0A);
        // Above the printed size the full-width Mushaf lines can't grow taller
        // without spilling off-screen, so switch to a reflowed, vertically
        // scrollable layout: lines render at true size, wrap, and the page
        // grows downward. At/below 1.0 we keep the pixel-exact one-screen page.
        final reflow = view.scale > 1.0;
        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            final pageNumber = Center(
              child: Text(
                '${widget.layout.page}',
                style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
              ),
            );
            final headerDark = view.theme == ReaderTheme.dark && !isColored;
            // Running-head colour tracks the page-number muted tone, lightened
            // on the dark page so it stays legible.
            final pageHeader = WMushafPageHeader(
              surahName: _pageSurahName,
              page: widget.layout.page,
              color: headerDark ? Colors.white70 : context.brand.muted,
            );

            // Enlarged: merge consecutive text lines into one continuously
            // wrapping, justified paragraph — words flow to the screen edge and
            // carry to the next row instead of each printed line wrapping on its
            // own. The page grows downward in a vertical scroll, whose axis
            // doesn't fight the reader's horizontal page-swipe.
            if (reflow) {
              final children = <Widget>[];
              final paragraph = <InlineSpan>[];
              void flushParagraph() {
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
                    flushParagraph();
                    children.add(_surahHeader(line, dark: headerDark));
                    break;
                  case LineType.basmala:
                    flushParagraph();
                    children.add(WBasmalaLine(fontSize: 28.sp * view.scale, color: fg));
                    break;
                  case LineType.spacer:
                    flushParagraph();
                    children.add(SizedBox(height: 8.h));
                    break;
                  case LineType.text:
                    // Separate the printed line break so the last word of one
                    // line doesn't glue to the first word of the next.
                    if (paragraph.isNotEmpty) {
                      paragraph.add(const TextSpan(text: ' '));
                    }
                    paragraph.addAll(
                      _lineSpans(
                        line,
                        cubit: cubit,
                        selected: view.selected,
                        playing: playing,
                        bookmarks: view.bookmarks,
                        fontFamily: fontFamily,
                        mode: view.mode,
                        scale: view.scale * pageScale,
                        color: fg,
                        wrap: true,
                        brightness: view.theme == ReaderTheme.dark ? Brightness.dark : Brightness.light,
                      ),
                    );
                    break;
                }
              }
              flushParagraph();

              return Container(
                color: readerBackground(view.theme, colored: isColored),
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

            // Exact mode: each line fits the page width and the page fills one
            // screen. Short pages (Fatihah, Baqarah opening, last few) have
            // fewer lines and center as a block inside the available space.
            final lineWidgets = widget.layout.lines
                .map((line) {
                  switch (line.type) {
                    case LineType.surahHeader:
                      return _surahHeader(line, dark: headerDark);
                    case LineType.basmala:
                      return WBasmalaLine(fontSize: 32.sp * view.scale, color: fg);
                    case LineType.spacer:
                      return SizedBox(height: 8.h);
                    case LineType.text:
                      return _renderTextLine(
                        line,
                        cubit: cubit,
                        selected: view.selected,
                        playing: playing,
                        bookmarks: view.bookmarks,
                        fontFamily: fontFamily,
                        mode: view.mode,
                        scale: view.scale * pageScale,
                        color: fg,
                        wrap: false,
                        brightness: view.theme == ReaderTheme.dark ? Brightness.dark : Brightness.light,
                      );
                  }
                })
                .toList(growable: false);

            final isFullPage = widget.layout.lines.length >= 12;
            // The openers (pp. 1–2) are centred with lots of spare vertical
            // room, so add breathing space between their lines. Full pages stay
            // tight — spaceEvenly already distributes their gaps.
            final openerGap = widget.layout.page <= 2 ? 7.h : 0.0;
            final wrappedLines = lineWidgets
                .map((w) {
                  if (w is WSurahHeader) return w;
                  final fitted = FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: w);
                  return openerGap > 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: openerGap),
                          child: fitted,
                        )
                      : fitted;
                })
                .toList(growable: false);

            return Container(
              color: readerBackground(view.theme, colored: isColored),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pageHeader,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: isFullPage ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
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
  }

  /// Arabic short name of the surah at the top of the page (the running-head
  /// label). Empty until [_surahs] loads.
  String get _pageSurahName {
    final refs = widget.layout.allAyahRefs;
    if (refs.isEmpty) return '';
    final surah = _surahs[refs.first.surah];
    if (surah == null) return '';
    return surah.arabic.isNotEmpty ? surah.arabic : surah.arabicLong;
  }

  /// Surah header for [line], falling back to the loaded surah list when the
  /// (V4) header line carries no text.
  WSurahHeader _surahHeader(MLine line, {required bool dark}) {
    final surah = _surahs[line.surahNumber];
    return WSurahHeader(
      title: line.text.isNotEmpty
          ? line.text
          : (surah?.arabicLong.isNotEmpty ?? false ? surah?.arabicLong ?? '' : surah?.arabic ?? ''),
      surahNumber: surah?.number ?? line.surahNumber,
      ayahCount: surah?.totalAyah,
      dark: dark,
    );
  }

  /// Exact mode: one printed line as its own centered, fit-to-width RichText.
  Widget _renderTextLine(
    MLine line, {
    required CBMushafReader cubit,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required EQuranFontMode mode,
    required double scale,
    required Color color,
    required bool wrap,
    required Brightness brightness,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: _lineSpans(
            line,
            cubit: cubit,
            selected: selected,
            playing: playing,
            bookmarks: bookmarks,
            fontFamily: fontFamily,
            mode: mode,
            scale: scale,
            color: color,
            wrap: wrap,
            brightness: brightness,
          ),
        ),
      ),
    );
  }

  /// Ayah-grouped glyph spans for one printed [line] — shared by the exact
  /// per-line renderer and the reflowed continuous-paragraph builder. Each ayah
  /// group keeps its own tap recognizer and selection/playback/bookmark tint.
  List<InlineSpan> _lineSpans(
    MLine line, {
    required CBMushafReader cubit,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required EQuranFontMode mode,
    required double scale,
    required Color color,
    required bool wrap,
    required Brightness brightness,
  }) {
    final isColored = mode.isColored;
    final groups = <_AyahGroup>[];
    _AyahGroup? current;
    for (final w in line.words) {
      final ref = ParamAyahRef(surah: w.surah, ayah: w.ayah);
      var group = current;
      if (group == null || group.ref.key != ref.key) {
        group = _AyahGroup(ref: ref);
        groups.add(group);
        current = group;
      }
      group.glyphs.add(_glyphFor(w, mode));
    }

    final spans = <InlineSpan>[];
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final isSelected = selected?.key == group.ref.key;
      final isPlaying = playing?.key == group.ref.key;
      final isBookmarked = bookmarks.containsKey(group.ref.key);
      spans.add(
        TextSpan(
          text: group.glyphs.join(' '),
          recognizer: _recogniser(group.ref, cubit),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 28.sp * scale,
            // Coloured (V4) glyphs supply their own colour via the font's
            // palette — never override it, just tint the background for
            // selection/playback. Plain modes recolour the now-playing ayah.
            color: isColored ? color : (isPlaying ? AppColorsLight.accent : color),
            fontWeight: FontWeight.w500,
            // Tight leading keeps exact pages packed; reflowed pages need room
            // between wrapped rows so stacked lines stay legible.
            height: wrap ? 1.9 : 1.0,
            // Priority: live selection → now-playing → saved bookmark colour.
            backgroundColor: isSelected
                ? (brightness == Brightness.dark
                      ? AppColors.surfaceLightGreen.withValues(alpha: 0.22)
                      : AppColors.surfaceLightGreen)
                : (isPlaying
                      ? AppColors.accentGoldAmber.withValues(alpha: 0.15)
                      : (isBookmarked ? bookmarkHighlightFromHex(bookmarks[group.ref.key]) : null)),
          ),
        ),
      );
      if (i != groups.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }
}

/// Reading-surface colour for [theme], shared by the page and the reader
/// screen background so the whole screen recolours as one. [colored] (V4
/// tajweed) glyphs bake their colours — including black base letters — into the
/// font palette, which can't be recoloured for a dark surface, so tajweed is
/// locked to a light page even when the reader theme is dark.
Color readerBackground(ReaderTheme theme, {required bool colored}) {
  if (colored && theme == ReaderTheme.dark) return AppColors.paperCream;
  switch (theme) {
    case ReaderTheme.light:
      return AppColors.paperWarm;
    case ReaderTheme.sepia:
      return AppColors.paperCream;
    case ReaderTheme.dark:
      return AppColors.darkBackground;
  }
}

/// The glyph string to render for [w] under [mode]: V4 colour glyphs, V2
/// glyphs (falling back to V1 when absent), or V1.
String _glyphFor(MWord w, EQuranFontMode mode) {
  switch (mode) {
    case EQuranFontMode.tajweedV4:
      return w.qpcV4 ?? '';
    case EQuranFontMode.plainV2:
      final v2 = w.qpcV2;
      return (v2 != null && v2.isNotEmpty) ? v2 : w.qpcV1;
    case EQuranFontMode.plainV1:
      return w.qpcV1;
  }
}

class _AyahGroup {
  _AyahGroup({required this.ref}) : glyphs = <String>[];
  final ParamAyahRef ref;
  final List<String> glyphs;
}
