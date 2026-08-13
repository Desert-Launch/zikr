import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_font_loader.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_theme.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_ayah_highlight_text.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_line.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_footer.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_reflow.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';

/// Renders one Mushaf page from its [MQpcV4Page] using the QPC-V4 colour fonts.
///
/// This is the single reader render path: tajweed is baked into the per-page
/// colour font (`fontMode == tajweedV4`), or collapsed to a plain uniform colour
/// (`plainV2`). Ayahs are grouped so tapping any word selects the whole ayah,
/// and selection / now-playing / bookmark tints are painted behind the glyphs by
/// [WAyahHighlightText].
///
/// Two layouts, chosen by the reader's text size:
/// - at or below [kBigTextThreshold] the page mirrors the printed Madani page —
///   each printed line is one [WMushafLine], fitted to the page width, and the
///   page fills exactly one screen;
/// - above it the printed line breaks are dissolved and each run of verse lines
///   reflows as one continuous stream through [WMushafPageReflow], so enlarged
///   text fills every row instead of stranding two words on a row of its own.
class WMushafV4Page extends StatefulWidget {
  const WMushafV4Page({required this.layout, this.continuousHeight, super.key});

  final MQpcV4Page layout;

  /// Height of one screen, passed in only by the reader's **continuous**
  /// (vertical) mode, where the page's slot is unbounded.
  ///
  /// Non-null puts the page in continuous mode: it lays out at its natural
  /// height — floored at this — and carries no scroll view of its own, so the
  /// list around it scrolls straight through a page break. Null is paged mode:
  /// the page fills the slot it was given and scrolls inside it if enlarged
  /// text outgrows it.
  final double? continuousHeight;

  @override
  State<WMushafV4Page> createState() => _WMushafV4PageState();
}

class _WMushafV4PageState extends State<WMushafV4Page> {
  late final DSQpcV4FontLoader _fonts = Modular.get<DSQpcV4FontLoader>();
  Map<int, MSurah> _surahs = const {};

  /// Cached result of [_printSize] — the measurement lays out every line on the
  /// page, so it must not run on a rebuild that only changed a colour or the
  /// selected ayah. Width and family are the only inputs that can move it.
  double? _printSizeCache;
  double? _printSizeWidth;
  String? _printSizeFamily;

  /// The glyph size at which this page's text fills a [width]-wide column — the
  /// page's 100%, before the reader's scale.
  ///
  /// Solved from the widest line the printed Mushaf set justified, so that line
  /// reaches both margins and every other line on the page — set at the same
  /// size, as the printed page does — falls where the print does. Lines the
  /// layout marks `isCentered` (a surah's closing line, an opener) are excluded:
  /// they are short by design, and fitting the page to one of them would blow
  /// the rest of the page off the screen. A page with nothing but centred lines
  /// — the openers on pp. 1–2, which the printed Mushaf also sets large — falls
  /// back to its widest line.
  double _printSize(double width, String fontFamily) {
    final cached = _printSizeCache;
    if (cached != null &&
        _printSizeWidth == width &&
        _printSizeFamily == fontFamily) {
      return cached;
    }

    const measure = WMushafLine.measureSize;
    var widest = 0.0;
    var widestJustified = 0.0;
    for (final block in widget.layout.blocks) {
      if (block is! MQpcV4LineBlock) continue;
      final natural = mushafLineNaturalWidth(
        block,
        fontFamily: fontFamily,
        size: measure,
      );
      if (natural > widest) widest = natural;
      if (!block.isCentered && natural > widestJustified) {
        widestJustified = natural;
      }
    }

    final natural = widestJustified > 0 ? widestJustified : widest;
    final size = natural <= 0 ? measure : measure * (width * 0.995 / natural);

    _printSizeCache = size;
    _printSizeWidth = width;
    _printSizeFamily = fontFamily;
    return size;
  }

  @override
  void initState() {
    super.initState();
    _fonts.preloadWindow(widget.layout.page);
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await Modular.get<DSLocalQuran>().loadSurahs();
    if (!mounted) return;
    setState(() => _surahs = {for (final s in surahs) s.number: s});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBMushafReader>(context);
    final page = widget.layout.page;

    return BlocSelector<
      CBMushafReader,
      SMushafReader,
      ({
        ParamAyahRef? selected,
        ReaderTheme theme,
        EQuranFontMode mode,
        double fontScale,
        bool bold,
        Map<String, String?> bookmarks,
      })
    >(
      selector: (s) => (
        selected: s.selectedAyah,
        theme: s.theme,
        mode: s.fontMode,
        fontScale: s.fontScale,
        bold: s.bold,
        bookmarks: s.bookmarks,
      ),
      builder: (context, view) {
        final isDark = view.theme == ReaderTheme.dark;
        final tajweed = view.mode == EQuranFontMode.tajweedV4;

        if (!_fonts.isPageReady(page) || widget.layout.blocks.isEmpty) {
          return SizedBox(
            // A page still waiting on its font must hold a screen's worth of
            // space in continuous mode, or the pages below it slide up and then
            // snap back down the moment the glyphs arrive.
            height: widget.continuousHeight,
            child: Container(
              color: readerBackground(view.theme),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final fontFamily = _fonts.familyFor(
          page,
          dark: isDark,
          tajweed: tajweed,
        );
        final baseColor = isDark
            ? const Color(0xFFF2E9D8)
            : const Color(0xFF0A0A0A);
        final markerColor = isDark
            ? const Color(0xFFE9C46A)
            : AppColorsLight.primary;
        final muted = context.brand.muted;
        final headerColor = isDark ? Colors.white70 : muted;
        // The sajdah mark is the one thing in the footer worth spotting from a
        // glance, so it leaves the muted running-foot grey behind: a light blue
        // on the dark page, a deep ink blue on the light/sepia ones.
        final sajdahColor = isDark
            ? const Color(0xFF8AB4F8)
            : const Color(0xFF1A4F9C);
        final brightness = isDark ? Brightness.dark : Brightness.light;

        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            final bigText = isBigTextScale(view.fontScale);
            final hPad = 5.w;

            // The page's own width decides its glyph size, so it has to be known
            // before a single line is built — hence the outer LayoutBuilder.
            return LayoutBuilder(
              builder: (context, pageConstraints) {
                final baseSize = _printSize(
                  pageConstraints.maxWidth - hPad * 2,
                  fontFamily,
                );
                final lineWidgets = _blockWidgets(
                  context: context,
                  cubit: cubit,
                  bigText: bigText,
                  baseSize: baseSize,
                  selected: view.selected,
                  playing: playing,
                  bookmarks: view.bookmarks,
                  fontFamily: fontFamily,
                  baseColor: baseColor,
                  markerColor: markerColor,
                  brightness: brightness,
                  fontScale: view.fontScale,
                  bold: view.bold,
                  isDark: isDark,
                );

                final isFullPage = widget.layout.blocks.length >= 12;
                // The openers (pp. 1–2) sit centred with spare vertical room, so
                // add breathing space between their lines.
                final openerGap = page <= 2 ? 7.h : 0.0;
                final wrapped = lineWidgets
                    .map((w) {
                      if (w is WSurahHeader || openerGap == 0) return w;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: openerGap),
                        child: w,
                      );
                    })
                    .toList(growable: false);

                // A reflowed run stacks from the very top of the viewport, and
                // QPC tashkeel reach well above the font's ascent — without this
                // the first row's marks are shaved off by the scroll view's clip.
                // The printed layout distributes its lines and never needs it.
                final topPad = bigText
                    ? baseSize * view.fontScale * kPillPadTop
                    : 0.0;

                // One screen's worth of height. In paged mode that is the slot
                // the PageView handed down; in continuous mode the slot is
                // unbounded, so the reader passes the viewport height in.
                final screenHeight =
                    widget.continuousHeight ?? pageConstraints.maxHeight;

                // The page is exactly as tall as its content needs, floored at
                // one screen.
                //
                // `mainAxisSize.min` under a minHeight is what does it: the
                // Column measures its children against unbounded height, then
                // the constraint floors the result — so a printed page that
                // falls short of a screen still gets the slack `spaceEvenly`
                // spreads between its lines, and an enlarged page that outgrows
                // a screen simply reports the taller height. THAT is what makes
                // continuous scrolling work: the page never has to scroll
                // itself, so the list around it is the only scrollable and a
                // page break is just another line boundary.
                final body = ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Container(
                    color: readerBackground(view.theme),
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 8.h,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: topPad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        // Reflowed runs are already as tall as their text needs;
                        // distributing them would just push the stream apart, so
                        // big text stacks from the top.
                        mainAxisAlignment: bigText
                            ? MainAxisAlignment.start
                            : (isFullPage
                                  ? MainAxisAlignment.spaceEvenly
                                  : MainAxisAlignment.center),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WMushafPageHeader(
                            surahName: _pageSurahName,
                            page: page,
                            color: headerColor,
                          ),
                          ...wrapped,
                          SizedBox(height: 4.h),
                          WMushafPageFooter(
                            page: page,
                            color: muted,
                            sajdahColor: sajdahColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // Paged mode keeps a scroll view of its own, because a page
                // enlarged past its slot has nowhere else to go. Continuous mode
                // must NOT have one — a second scrollable inside the list is
                // exactly what makes a drag stop dead at a page boundary.
                if (widget.continuousHeight != null) return body;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: body,
                );
              },
            );
          },
        );
      },
    );
  }

  /// Turns the page's blocks into widgets.
  ///
  /// Below the big-text threshold that is one [WMushafLine] per printed line —
  /// the printed layout, unchanged. Above it, consecutive verse lines are
  /// collected into runs and each run is handed to [WMushafPageReflow] as a
  /// single stream, so words fill every row instead of being stranded on a row
  /// belonging to their printed line. Surah headers and basmalas keep their own
  /// centred widgets in both modes, and close the run they interrupt.
  List<Widget> _blockWidgets({
    required BuildContext context,
    required CBMushafReader cubit,
    required bool bigText,
    required double baseSize,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required Color baseColor,
    required Color markerColor,
    required Brightness brightness,
    required double fontScale,
    required bool bold,
    required bool isDark,
  }) {
    final widgets = <Widget>[];
    final run = <MQpcV4LineBlock>[];

    void flushRun() {
      if (run.isEmpty) return;
      widgets.add(
        WMushafPageReflow(
          blocks: List<MQpcV4LineBlock>.of(run),
          baseSize: baseSize,
          selected: selected,
          playing: playing,
          bookmarks: bookmarks,
          fontFamily: fontFamily,
          baseColor: baseColor,
          markerColor: markerColor,
          brightness: brightness,
          fontScale: fontScale,
          bold: bold,
          onSelect: cubit.selectAyah,
          onLongPress: (ref) => toggleAyahBookmark(context, ref, cubit),
        ),
      );
      run.clear();
    }

    for (final block in widget.layout.blocks) {
      switch (block) {
        case MQpcV4SurahHeaderBlock():
          flushRun();
          widgets.add(_surahHeader(block.surahNumber, dark: isDark));
        case MQpcV4BasmalaBlock():
          flushRun();
          widgets.add(_basmala(baseColor, baseSize * fontScale, bold: bold));
        case MQpcV4LineBlock():
          if (bigText) {
            run.add(block);
          } else {
            widgets.add(
              WMushafLine(
                block: block,
                baseSize: baseSize,
                selected: selected,
                playing: playing,
                bookmarks: bookmarks,
                fontFamily: fontFamily,
                baseColor: baseColor,
                markerColor: markerColor,
                brightness: brightness,
                fontScale: fontScale,
                bold: bold,
                onSelect: cubit.selectAyah,
                onLongPress: (ref) => toggleAyahBookmark(context, ref, cubit),
              ),
            );
          }
      }
    }
    flushRun();
    return widgets;
  }

  /// Arabic short name of the surah at the top of the page.
  String get _pageSurahName {
    final refs = widget.layout.allAyahRefs;
    if (refs.isEmpty) return '';
    final surah = _surahs[refs.first.surah];
    if (surah == null) return '';
    return surah.arabic.isNotEmpty ? surah.arabic : surah.arabicLong;
  }

  Widget _surahHeader(int surahNumber, {required bool dark}) {
    final surah = _surahs[surahNumber];
    return WSurahHeader(
      title: surah == null
          ? ''
          : (surah.arabicLong.isNotEmpty ? surah.arabicLong : surah.arabic),
      surahNumber: surah?.number ?? surahNumber,
      ayahCount: surah?.totalAyah,
      dark: dark,
    );
  }

  /// Amiri's size as a fraction of the page's QPC glyph size, so the basmala
  /// reads at the same visual weight as the verses around it.
  ///
  /// A correction is unavoidable because the two fonts are not interchangeable
  /// at equal point size: a QPC line spends most of its em box on tashkeel
  /// while Amiri spends it on the letters, so the same nominal size renders
  /// Amiri roughly 1.4–1.7x larger (measured on device by comparing ascender
  /// strokes). The ratio is the reciprocal of that factor.
  ///
  /// It cannot be avoided by using the page's own glyphs: QPC-V4 marks its
  /// basmala lines with `line_type: basmallah` and EMPTY `first_word_id` /
  /// `last_word_id` — all 112 of them — so the dataset carries no basmala
  /// glyphs to render (see `DSQpcV4Data._buildBlocks`). A separate Amiri text
  /// is the only option, and this constant is the whole of its relationship to
  /// the page.
  ///
  /// 0.7 is the 1.4x (least-aggressive) end of that measured range. It was 0.6
  /// — the 1.7x end — which is what made the basmala read visibly smaller than
  /// its surroundings.
  static const double _basmalaSizeRatio = 0.7;

  /// [textSize] is the page's rendered glyph size — the basmala is set as a
  /// fraction of it ([_basmalaSizeRatio]) so it grows with the page rather than
  /// with the screen, and stays matched at every text size and zoom level.
  Widget _basmala(Color color, double textSize, {required bool bold}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      // Scaled down if the enlarged size would exceed the page width, so the
      // basmala can never wrap or clip either.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: textSize * _basmalaSizeRatio,
            color: color,
            height: 1.4,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Reading-surface colour for [theme]. The QPC-V4 colour fonts carry a dark
/// variant, so tajweed no longer needs to be locked to a light page.
Color readerBackground(ReaderTheme theme) {
  switch (theme) {
    case ReaderTheme.white:
      return Colors.white;
    case ReaderTheme.light:
      return AppColors.paperWarm;
    case ReaderTheme.dark:
      return AppColors.darkBackground;
  }
}
