import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_data.dart';
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
import 'package:quran/modules/quran/presentation/widgets/w_playing_ayah_anchor.dart';
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

/// Family of the Uthmani text font bundled for the reader's non-QPC glyphs.
///
/// The pubspec name says "ayah number" because the rosette is what it was first
/// pulled in for, but the face is a complete Uthmani Quran font: it carries the
/// whole Arabic block, and only the digit glyphs have COLR/CPAL colour layers,
/// so letters set in it take the colour the [TextStyle] asks for. That makes it
/// the right — and only bundled — face for the basmala, which the QPC page fonts
/// cannot draw (see [_WMushafV4PageState._basmala]).
const String kMushafUthmaniFamily = 'ayahNumberV4';

/// The basmala, in the Uthmani orthography the Mushaf prints.
const String kBasmalaText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// Line-box height of the basmala, as a multiple of its own glyph size.
///
/// Below the font's natural 1.76, on purpose, and for the same reason the
/// printed lines use `height: 1.0`: the box is the space the block *reserves*,
/// while the tashkeel are allowed to reach out of it into the gap the page
/// layout leaves around every line. A box at the natural height would reserve
/// two printed lines' worth of room for one line of text.
const double kBasmalaLineHeight = 1.25;

/// Gap between a surah's banner and the basmala under it.
///
/// The two are emitted as ONE block (see [_SurahOpening]) precisely so this gap
/// is a fixed, small number instead of whatever the page's even distribution
/// happened to hand out. A surah's opening reads as one unit on the printed
/// page — the name, then the basmala tucked under it — not as two lines that
/// happen to be adjacent.
const double kSurahOpeningGap = 14.0;

/// How much of the text column the page's widest justified line spans — and,
/// through that, the ONLY control the page has over its line spacing.
///
/// ## Why line spacing and glyph size are the same knob
///
/// A printed page holds fifteen lines in one screen, and the page layout hands
/// every scrap of leftover height to the gaps between them. So the distance
/// from one line to the next is fixed by arithmetic — usable height ÷ 15 — and
/// nothing about how that height is divided up can change it. Padding a line
/// only takes the same pixels back out of the gap either side of it; opening
/// the `height` multiplier does the same.
///
/// What *can* change is how much of that fixed pitch the ink fills. Shrinking
/// the glyphs leaves the pitch exactly where it was and simply puts less ink
/// inside it, which is what reads as air between the lines. At 1.0 the widest
/// line runs margin to margin and the page is at the printed Mushaf's own
/// density — handsome, and tight. Every 0.01 below that buys roughly half a
/// logical pixel of daylight between every pair of lines, and costs the same
/// half pixel as side margin, since the lines no longer quite reach the edges.
///
/// It is capped a hair under 1.0 even at its tightest: a widest line solved to
/// span the column *exactly* can come out a hundredth of a pixel over and wrap,
/// stranding its last word on a row of its own.
const double kPageFillFactor = 0.99;

/// Gap between the running head and the first line, and between the last line
/// and the running foot.
///
/// The one number that controls how tightly the page chrome sits against the
/// text. It only means anything because the head and foot are reserved at a
/// fixed height and laid out OUTSIDE the block distribution — while they were
/// children of it, this gap was a line gap by construction and could not be set
/// independently of the page's whole rhythm.
double get kMushafChromeGap => 12.h;

/// The page's side margin — the white edge a printed Mushaf leaves around its
/// text block, and what keeps the glyphs off the screen's bezel.
///
/// It is not free, and that is why it stayed a hairline for so long: the text
/// column's width is what the page's glyph size is solved from, so every pixel
/// of margin makes the whole page a shade smaller. But a hairline was the wrong
/// trade. The widest justified line spans the column *exactly* by construction,
/// so a page with no margin has lines that literally touch the glass — and the
/// highlight pill behind a selected ayah, which is drawn wider than its glyphs,
/// ran off both edges of the screen.
///
/// A printed Mushaf pays exactly this price for exactly this reason.
double get kMushafSideMargin => 10.w;

/// Extra leading every printed line carries while the page is in landscape.
///
/// The page's glyph size is solved from its WIDTH — that is what makes the
/// widest justified line span the column exactly, on any screen. Turn a tablet
/// sideways and the column gets half as wide again, so the glyphs grow with it
/// while the height available to stack them in shrinks. Portrait has slack left
/// over and `spaceBetween` spends it on the gaps between lines; landscape has
/// none, every box sits at `height: 1.0`, and the lines close up until the
/// tashkeel of one collide with the line above it.
///
/// 0.6 puts a line's pitch at 1.6x its glyph size — comfortably past the ~1.3x
/// the distributed slack works out to on a portrait tablet, because a landscape
/// line is set half again as large and wants the air to match. It is added to
/// the line height rather than to a gap between lines so the highlight pills
/// grow with it — [WMushafLine] already discounts the leading out of its pill
/// padding.
const double kLandscapeLineHeightBoost = 0.6;

/// The surah opening's metrics in landscape, in ems of the page's own glyph
/// size — the banner's height, the gap under it, and the gaps under the whole
/// opening.
///
/// Portrait sets all four in `.h` units or in flat logical pixels, and both go
/// wrong the moment the tablet turns. A `.h` unit is a share of the SCREEN's
/// height, so it loses about a third of itself when the long side becomes the
/// short one; a flat pixel constant does not move at all. Meanwhile the glyphs
/// they are meant to sit against have grown by half again, because the page is
/// solved from its width. The banner ends up a thin strip under enormous text
/// and the basmala crowds up against it.
///
/// Tying them to [baseSize] instead makes the opening scale with the text it
/// belongs to, which is the relationship portrait already has — these are the
/// portrait proportions, measured and re-expressed.
const double kLandscapeSurahHeaderEm = 1.25;
const double kLandscapeOpeningGapEm = 0.45;
const double kLandscapeOpeningTailEm = 0.40;
const double kLandscapeOpenerBasmalaTailEm = 0.55;
const double kLandscapeFatihaHeaderEm = 0.40;

/// How wide a surah-heading basmala is set, as a fraction of the text column.
///
/// This IS the basmala's width: it is fitted to exactly this slice of the page,
/// undistorted, with its own word spacing intact. Raise it and the line grows,
/// lower it and it shrinks — on every page, at every glyph size, on any screen.
///
/// Left to itself the run measures 6.59 em against a full printed line's ~16.2,
/// so it would sit at about 40% of the column; anything above that is the line
/// being stretched.
///
/// It replaced a `wordSpacing` stretch, which widened the line by prising the
/// four words apart. That is not what a stretched basmala looks like — the print
/// keeps the word gaps and elongates the letters instead (kashida), and the
/// spaced-out version read as four words that had drifted rather than one line
/// set wide. Scaling the whole run keeps the spacing the Mushaf gave it.
const double kBasmalaWidthFraction = 0.4;

/// The one basmala the page leaves entirely alone: Al-Baqara's, opening page 2.
///
/// That page is the Mushaf's second illuminated opening and the print lays it
/// out on its own terms — more air, fewer lines, an unstretched basmala. Every
/// other surah heading gets [kBasmalaStretch].
///
/// Al-Fatiha's basmala never reaches here at all: it is a numbered verse rather
/// than a heading, so the page draws it as an ordinary line.
///
/// This single predicate drives BOTH the stretch and the gap under the basmala
/// ([kOpenerBasmalaTailGap] vs [kSurahOpeningTailGap]) — they were two separate
/// rules that happened to be equal, which is one rule too many to keep in step.
bool isIlluminatedOpener({required int page, required int surahNumber}) => page == 2 && surahNumber == 2;

/// Gap under a surah's basmala, before the first verse of the surah.
///
/// It sits INSIDE [_SurahOpening], so it is a fixed number rather than a share
/// of the page's slack — the opening reads as one unit and the first verse
/// should not be pushed as far from the basmala as two ordinary lines are from
/// each other.
double get kSurahOpeningTailGap => 4.h;

/// The same gap on Al-Baqara's opening page, which the printed Mushaf sets as
/// an illuminated page with far fewer lines and correspondingly more air.
double get kOpenerBasmalaTailGap => 14.h;

/// Gap under Al-Fatiha's banner, before its first verse.
///
/// Al-Fatiha is the one surah whose banner is followed straight by a line of
/// Quran: its basmala is verse 1, not a heading, so there is no basmala block to
/// sit between the two and take the space. Without a gap of its own the verse
/// reads as though it were part of the frame above it.
double get kFatihaHeaderGap => 10.h;

/// The text measure on the Mushaf's two opening pages, as a fraction of the
/// column — how wide their lines are allowed to run.
///
/// Every other page is solved so its widest line spans the column, which is
/// what the print does: one size per page, chosen so the justified lines reach
/// both margins. The openers are the exception. The print sets them inside a
/// decorative frame on a deliberately narrow measure, and — this is the part
/// the renderer cannot infer — it sets BOTH of them at the same point size.
///
/// Every line on pp. 1–2 is marked `is_centered`, so there is no justified line
/// to solve against and the page falls back to its widest, whatever that is.
/// Al-Fatiha's longest verse is much shorter than Al-Baqara's, so solving each
/// page on its own blew Al-Fatiha up to fill a width the print never gives it.
/// The two fractions differ for exactly that reason: they are what one shared
/// point size looks like expressed per page.
double kOpenerTextWidth(int page) => page == 1 ? 0.85 : 0.85;

class _WMushafV4PageState extends State<WMushafV4Page> {
  late final DSQpcV4FontLoader _fonts = Modular.get<DSQpcV4FontLoader>();
  late final DSLocalQuran _quran = Modular.get<DSLocalQuran>();
  late final DSQpcV4Data _v4 = Modular.get<DSQpcV4Data>();

  /// The basmala's word glyph runs — the same four words on every page that
  /// prints one, so they are resolved once for the whole reader and shared.
  static List<String>? _basmalaWords;

  /// Whether this page opens a surah, and so needs page 1's glyphs and font.
  /// Most pages do not, and they must not pay to register a font they will
  /// never draw with.
  late final bool _printsBasmala = widget.layout.blocks.any((b) => b is MQpcV4BasmalaBlock);
  Map<int, MSurah> _surahs = const {};

  /// True while a [DSQpcV4FontLoader.loadPage] kicked off from [build] is in
  /// flight, so a rebuild while it runs does not start a second one.
  bool _loadingFont = false;

  /// Font families this page has already asked the loader for.
  ///
  /// A registration that fails leaves the family unready for good (the loader
  /// logs and moves on), and [build] would otherwise ask for it again on the
  /// rebuild its own failure triggered — re-reading the asset in a loop for as
  /// long as the page stayed on screen. One attempt per family; a theme or
  /// tajweed switch asks for a different family and so gets its own.
  final Set<String> _fontAttempts = <String>{};

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
    if (cached != null && _printSizeWidth == width && _printSizeFamily == fontFamily) {
      return cached;
    }

    const measure = WMushafLine.measureSize;
    var widest = 0.0;
    var widestJustified = 0.0;
    for (final block in widget.layout.blocks) {
      if (block is! MQpcV4LineBlock) continue;
      final natural = mushafLineNaturalWidth(block, fontFamily: fontFamily, size: measure);
      if (natural > widest) widest = natural;
      if (!block.isCentered && natural > widestJustified) {
        widestJustified = natural;
      }
    }

    final natural = widestJustified > 0 ? widestJustified : widest;
    final size = natural <= 0 ? measure : measure * (width * kPageFillFactor / natural);

    _printSizeCache = size;
    _printSizeWidth = width;
    _printSizeFamily = fontFamily;
    return size;
  }

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  /// Seeds the surah names.
  ///
  /// Synchronously when the list is already in the datasource's cache — which it
  /// is for every page after the first — so a page scrolled into view does not
  /// pay for a rebuild a microtask after it mounts.
  void _loadSurahs() {
    final cached = _quran.cachedSurahs;
    if (cached != null) {
      _surahs = {for (final s in cached) s.number: s};
      return;
    }
    _quran.loadSurahs().then((surahs) {
      if (!mounted) return;
      setState(() => _surahs = {for (final s in surahs) s.number: s});
    });
  }

  /// Registers the page font variant this page is about to paint with, and
  /// repaints when it lands.
  ///
  /// The reader's cubit warms fonts around the current page, but in continuous
  /// mode a fast scroll can bring a page on screen ahead of that window — and a
  /// theme or tajweed switch asks for a variant that page has never registered.
  /// Without this the page would sit on its spinner until something else
  /// happened to rebuild it.
  void _ensureFont(int page, {required bool dark, required bool tajweed}) {
    if (_loadingFont) return;
    final family = _fonts.familyFor(page, dark: dark, tajweed: tajweed);
    if (!_fontAttempts.add(family)) return;
    _loadingFont = true;
    _fonts.loadPage(page, dark: dark, tajweed: tajweed).whenComplete(() {
      _loadingFont = false;
      if (mounted) setState(() {});
    });
  }

  /// Resolves the shared basmala glyph runs, once per session.
  void _ensureBasmalaWords() {
    if (_basmalaWords != null) return;
    final cached = _v4.cachedBasmalaWords;
    if (cached != null) {
      _basmalaWords = cached;
      return;
    }
    _v4.basmalaWords().then((words) {
      _basmalaWords = words;
      if (mounted) setState(() {});
    });
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

        if (!_fonts.isPageReady(page, dark: isDark, tajweed: tajweed) || widget.layout.blocks.isEmpty) {
          if (widget.layout.blocks.isNotEmpty) {
            _ensureFont(page, dark: isDark, tajweed: tajweed);
          }
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

        final fontFamily = _fonts.familyFor(page, dark: isDark, tajweed: tajweed);
        final baseColor = isDark ? const Color(0xFFF2E9D8) : const Color(0xFF0A0A0A);
        final markerColor = isDark ? const Color(0xFFE9C46A) : AppColorsLight.primary;
        final muted = context.brand.muted;
        final headerColor = isDark ? Colors.white70 : muted;
        // The sajdah mark is the one thing in the footer worth spotting from a
        // glance, so it leaves the muted running-foot grey behind: a light blue
        // on the dark page, a deep ink blue on the light/sepia ones.
        final sajdahColor = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A4F9C);
        final brightness = isDark ? Brightness.dark : Brightness.light;

        // Read from the reader's provider rather than Modular: this rebuilds
        // during the pop transition, after the module has been disposed.
        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            final bigText = isBigTextScale(view.fontScale);
            final hPad = kMushafSideMargin;

            // Landscape is read off the viewport rather than off the page's own
            // constraints: in continuous mode the page is laid out with an
            // unbounded height, so comparing its own width against its height
            // would call every page portrait.
            final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

            // The page's own width decides its glyph size, so it has to be known
            // before a single line is built — hence the outer LayoutBuilder.
            return LayoutBuilder(
              builder: (context, pageConstraints) {
                // The text column: what every line, the basmala and the surah
                // banner are laid out across. Solved once here and handed down,
                // so no line needs a LayoutBuilder of its own — fifteen nested
                // relayout boundaries per page is a cost the scroll pays on
                // every page that comes into view.
                final columnWidth = pageConstraints.maxWidth - hPad * 2;
                // The openers run to a narrower measure than the rest of the
                // Mushaf — see [kOpenerTextWidth]. Everything downstream works
                // off this rather than the column: the glyph size is solved
                // from it, and it is the width each line is actually given, so
                // the highlight painter measures the same box it paints into.
                final isOpenerPage = page <= 2;
                final textWidth = isOpenerPage ? columnWidth * kOpenerTextWidth(page) : columnWidth;
                final baseSize = _printSize(textWidth, fontFamily);

                // The basmala is set in Al-Fatiha's own glyphs, which live in
                // page 1's font — a different file from this page's, and the
                // only one in the Mushaf that carries them. Both the font and
                // the glyph runs resolve lazily; until they land the basmala
                // falls back to a text setting, so it is never blank and never
                // shifts the page under the reader.
                String? basmalaFamily;
                if (_printsBasmala) {
                  _ensureBasmalaWords();
                  const source = DSQpcV4Data.basmalaSourcePage;
                  if (_fonts.isPageReady(source, dark: isDark, tajweed: tajweed)) {
                    basmalaFamily = _fonts.familyFor(source, dark: isDark, tajweed: tajweed);
                  } else {
                    _ensureFont(source, dark: isDark, tajweed: tajweed);
                  }
                }

                final lineWidgets = _blockWidgets(
                  context: context,
                  cubit: cubit,
                  bigText: bigText,
                  baseSize: baseSize,
                  textWidth: textWidth,
                  basmalaFamily: basmalaFamily,
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
                  lineHeightBoost: isLandscape ? kLandscapeLineHeightBoost : 0.0,
                  isLandscape: isLandscape,
                );

                final isFullPage = widget.layout.blocks.length >= 12;
                // The openers (pp. 1–2) sit centred with spare vertical room, so
                // add breathing space between their lines.
                final openerGap = page <= 2 ? 7.h : 0.0;
                final wrapped = lineWidgets
                    .map((w) {
                      // The surah banner keeps the full column on an opener —
                      // the print insets the TEXT inside the frame, not the
                      // frame itself — and so does everything on an ordinary
                      // page, where the measure is the column anyway.
                      if (w is WSurahHeader || w is _SurahOpening || !isOpenerPage) {
                        return w;
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: openerGap),
                        child: Center(
                          child: SizedBox(width: textWidth, child: w),
                        ),
                      );
                    })
                    .toList(growable: false);

                // A reflowed run stacks from the very top of the viewport, and
                // QPC tashkeel reach well above the font's ascent — without this
                // the first row's marks are shaved off by the scroll view's clip.
                // The printed layout distributes its lines and never needs it.
                final topPad = bigText ? baseSize * view.fontScale * kPillPadTop : 0.0;

                // One screen's worth of height. In paged mode that is the slot
                // the PageView handed down; in continuous mode the slot is
                // unbounded, so the reader passes the viewport height in.
                final screenHeight = widget.continuousHeight ?? pageConstraints.maxHeight;

                // The page's own top/bottom margin.
                final vPad = 5.h;
                // The running head and foot are laid out at a FIXED height and
                // sit OUTSIDE the block distribution, separated from the text
                // by [kMushafChromeGap] and nothing else.
                //
                // They used to be children of the distributing Column, which
                // meant the gap under the head and the gap over the foot were
                // whatever a line gap happened to be — there was no way to
                // tighten the chrome without tightening the whole page. Pulling
                // them out buys that control twice over: the chrome gap is now a
                // number, and the two gaps it replaced go back into the pool the
                // lines share, so the text breathes more rather than less.
                final headerHeight = WMushafPageHeader.heightOf(context);
                final footerHeight = WMushafPageFooter.heightOf(context);
                final chromeGap = kMushafChromeGap;

                // What is left for the text once the chrome has had its share.
                // Because the chrome's height is fixed rather than measured,
                // this arithmetic is exact: a short page comes out at EXACTLY
                // one screen, with the foot on the bottom margin and no slack
                // hanging underneath it.
                final blocksMinHeight = (screenHeight - vPad * 2 - headerHeight - footerHeight - chromeGap * 2).clamp(
                  0.0,
                  double.infinity,
                );

                final body = Container(
                  color: readerBackground(view.theme),
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WMushafPageHeader(surahName: _pageSurahName, page: page, color: headerColor),
                      SizedBox(height: chromeGap),
                      // The text, floored at the height the chrome left it — an
                      // enlarged page simply reports a taller one and the list
                      // around it scrolls through, which is what keeps
                      // continuous mode working.
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: blocksMinHeight),
                        child: Padding(
                          padding: EdgeInsets.only(top: topPad),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            // A full printed page spreads its lines over the
                            // whole column, which is the printed rhythm. The
                            // openers on pp. 1–2 and the Mushaf's last page hold
                            // far too few lines to spread down a screen without
                            // reading as a list, so they sit centred as a block;
                            // a reflowed run is already as tall as its text needs
                            // and stacks from the top.
                            mainAxisAlignment: bigText
                                ? MainAxisAlignment.start
                                : (isFullPage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: wrapped,
                          ),
                        ),
                      ),
                      SizedBox(height: chromeGap),
                      WMushafPageFooter(page: page, color: muted, sajdahColor: sajdahColor),
                    ],
                  ),
                );

                // Paged mode keeps a scroll view of its own, because a page
                // enlarged past its slot has nowhere else to go. Continuous mode
                // must NOT have one — a second scrollable inside the list is
                // exactly what makes a drag stop dead at a page boundary.
                if (widget.continuousHeight != null) return body;
                return SingleChildScrollView(physics: const ClampingScrollPhysics(), child: body);
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
    required double textWidth,
    required String? basmalaFamily,
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
    required double lineHeightBoost,
    required bool isLandscape,
  }) {
    // Portrait keeps every one of these at its printed value — `null` and the
    // `k*` constants below are what the page has always used.
    final headerHeight = isLandscape ? baseSize * kLandscapeSurahHeaderEm : null;
    final openingGap = isLandscape ? baseSize * kLandscapeOpeningGapEm : kSurahOpeningGap;
    final openingTailGap = isLandscape ? baseSize * kLandscapeOpeningTailEm : kSurahOpeningTailGap;
    final openerBasmalaTailGap = isLandscape ? baseSize * kLandscapeOpenerBasmalaTailEm : kOpenerBasmalaTailGap;
    final fatihaHeaderGap = isLandscape ? baseSize * kLandscapeFatihaHeaderEm : kFatihaHeaderGap;

    final widgets = <Widget>[];
    final run = <MQpcV4LineBlock>[];

    // The first line that carries the verse being recited is marked, so the
    // reader can scroll to the verse itself rather than to the top of the page
    // it sits on — which in landscape can be a screen and a half away.
    var anchored = false;
    bool carriesPlaying(MQpcV4LineBlock block) {
      final ref = playing;
      if (ref == null || anchored) return false;
      return block.segments.any(
        (seg) => seg.surah == ref.surah && seg.ayah == ref.ayah,
      );
    }

    /// Marks [child] as where the recitation is, the first time a line on this
    /// page carries the verse.
    Widget withAnchor(bool carries, Widget child) {
      final ref = playing;
      if (!carries || ref == null) return child;
      anchored = true;
      return WPlayingAyahAnchor(
        page: widget.layout.page,
        ayahKey: ref.key,
        child: child,
      );
    }

    void flushRun() {
      if (run.isEmpty) return;
      final carries = run.any(carriesPlaying);
      widgets.add(
        withAnchor(
          carries,
          WMushafPageReflow(
            blocks: List<MQpcV4LineBlock>.of(run),
            baseSize: baseSize,
            maxWidth: textWidth,
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
        ),
      );
      run.clear();
    }

    final blocks = widget.layout.blocks;
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      switch (block) {
        case MQpcV4SurahHeaderBlock():
          flushRun();
          // A surah's banner and its basmala go out as ONE child. The page
          // spreads its slack evenly between children, so leaving them as two
          // put a full line gap between the name and the basmala directly under
          // it — the one place on the page where that gap is wrong.
          final next = i + 1 < blocks.length ? blocks[i + 1] : null;
          final header = _surahHeader(block.surahNumber, dark: isDark, height: headerHeight);
          if (next is MQpcV4BasmalaBlock) {
            i++;
            final opener = isIlluminatedOpener(page: widget.layout.page, surahNumber: next.surahNumber);
            widgets.add(
              _SurahOpening(
                tailGap: opener ? openerBasmalaTailGap : openingTailGap,
                openingGap: openingGap,
                header: header,
                basmala: _basmala(
                  color: baseColor,
                  columnWidth: textWidth,
                  size: baseSize * fontScale,
                  family: basmalaFamily,
                  bold: bold,
                  stretch: !opener,
                ),
              ),
            );
          } else if (block.surahNumber == 1) {
            // Al-Fatiha: banner, then straight into verse 1. The gap the other
            // surahs get from their basmala block has to be put there by hand.
            widgets.add(_SurahOpening(header: header, tailGap: fatihaHeaderGap));
          } else {
            widgets.add(header);
          }
        case MQpcV4BasmalaBlock():
          flushRun();
          widgets.add(
            _basmala(
              color: baseColor,
              columnWidth: textWidth,
              size: baseSize * fontScale,
              family: basmalaFamily,
              bold: bold,
              stretch: !isIlluminatedOpener(page: widget.layout.page, surahNumber: block.surahNumber),
            ),
          );
        case MQpcV4LineBlock():
          if (bigText) {
            run.add(block);
          } else {
            final carries = carriesPlaying(block);
            widgets.add(
              withAnchor(
                carries,
                WMushafLine(
                  block: block,
                  baseSize: baseSize,
                  maxWidth: textWidth,
                  selected: selected,
                  playing: playing,
                  bookmarks: bookmarks,
                  fontFamily: fontFamily,
                  baseColor: baseColor,
                  markerColor: markerColor,
                  brightness: brightness,
                  fontScale: fontScale,
                  bold: bold,
                  lineHeightBoost: lineHeightBoost,
                  onSelect: cubit.selectAyah,
                  onLongPress: (ref) => toggleAyahBookmark(context, ref, cubit),
                ),
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

  /// [height] is null on a portrait page, where the banner keeps its own `.h`
  /// default; landscape passes one solved from the page's glyph size.
  Widget _surahHeader(int surahNumber, {required bool dark, double? height}) {
    final surah = _surahs[surahNumber];
    return WSurahHeader(
      title: surah == null ? '' : (surah.arabicLong.isNotEmpty ? surah.arabicLong : surah.arabic),
      surahNumber: surah?.number ?? surahNumber,
      ayahCount: surah?.totalAyah,
      dark: dark,
      height: height,
    );
  }

  /// The basmala line that opens 112 of the 114 surahs.
  ///
  /// Set in the Mushaf's own hand, in the page fonts' own glyphs — the same
  /// four words Al-Fatiha prints as its first verse, in page 1's font family,
  /// at this page's glyph size, minus the ayah rosette Al-Fatiha carries and a
  /// heading does not.
  ///
  /// ## Why it borrows from page 1
  ///
  /// QPC-V4 marks all 112 heading basmalas `line_type: basmallah` with EMPTY
  /// word ids, and each per-page font carries a glyph for every word on its own
  /// page and not one more — so there is genuinely nothing on those pages to
  /// draw. Al-Fatiha is the exception: its basmala is a numbered verse, so it
  /// exists as real words with real glyphs. Lifting them is what lets every
  /// basmala in the Mushaf be set in the same typeface as the verses around it
  /// rather than in a substitute face that reads as coming from another book.
  ///
  /// ## Why the size needs no constant
  ///
  /// [size] is the page's own glyph size, exactly what its verse lines are set
  /// at, so the basmala matches them in weight and colour with nothing to tune —
  /// including in tajweed mode, where it picks up page 1's baked palette like
  /// any other line. Its width then falls out of the glyphs themselves: the run
  /// measures 6.58 em against a full printed line's ~16 em, so it lands at about
  /// 40% of the column on any page, on any screen. That is the proportion the
  /// print holds. A surah heading is then set wider than that, to
  /// [kBasmalaWidthFraction] of the column.
  ///
  /// [FittedBox] is insurance only: on a page whose lines are all short — the
  /// openers — the solved glyph size can be large enough to push the run past
  /// the column, and scaling down is better than clipping. Normally it is a
  /// no-op.
  Widget _basmala({
    required Color color,
    required double columnWidth,
    required double size,
    required String? family,
    required bool bold,
    required bool stretch,
  }) {
    final words = _basmalaWords;
    if (family == null || words == null || words.isEmpty) {
      return _fallbackBasmala(color: color, columnWidth: columnWidth, size: size, bold: bold);
    }
    // U+200B between the words: zero width and shaping-transparent, so the
    // spacing baked into the glyph runs is the only spacing there is — the word
    // gaps stay exactly as the Mushaf set them however wide the line is drawn.
    final line = Text(
      words.join(kQpcWordBreak),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.w500,
        color: color,
        shadows: emboldenShadows(bold: bold, color: color, size: size),
      ),
    );

    // The illuminated opener is left at the page's own glyph size, so it matches
    // the verses around it exactly. FittedBox only guards the openers, whose
    // solved glyph size can be large enough to push the run past the column.
    if (!stretch) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        // The QPC line box is the glyph size and the tashkeel reach well past
        // it, exactly as on every other line of the page — clipping to it would
        // shave the marks off.
        clipBehavior: Clip.none,
        child: line,
      );
    }

    // Every other surah heading is drawn to a fixed slice of the column. The
    // whole run scales together, so the letterforms and the gaps between the
    // words keep the proportions the typeface gave them; only the size changes.
    return Center(
      child: SizedBox(
        width: (columnWidth * kBasmalaWidthFraction).clamp(0.0, columnWidth),
        child: FittedBox(fit: BoxFit.contain, clipBehavior: Clip.none, child: line),
      ),
    );
  }

  /// Shown for the frame or two before page 1's font and glyph runs arrive, and
  /// as a permanent floor if either ever fails to load.
  ///
  /// Set in the bundled Uthmani face and fitted to a fixed slice of the column
  /// ([kBasmalaWidthFraction]), because a substitute face cannot be matched to
  /// the page by point size — how much of the em box goes to the letters and
  /// how much to the tashkeel differs between designs, so any conversion
  /// constant is measured on one device against one page and drifts. Width is
  /// what the printed page actually holds constant.
  Widget _fallbackBasmala({
    required Color color,
    required double columnWidth,
    required double size,
    required bool bold,
  }) {
    final width = (columnWidth * kBasmalaWidthFraction).clamp(columnWidth * 0.28, columnWidth);
    // Arbitrary — FittedBox scales whatever comes out of it to [width], so this
    // only sets the precision of the measurement, never the rendered size.
    const nominal = 48.0;
    return Center(
      child: SizedBox(
        width: width,
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.none,
          child: Text(
            kBasmalaText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: kMushafUthmaniFamily,
              fontSize: nominal,
              color: color,
              height: kBasmalaLineHeight,
              shadows: emboldenShadows(bold: bold, color: color, size: nominal),
            ),
          ),
        ),
      ),
    );
  }
}

/// A surah's banner with its basmala tucked under it, as a single page block.
///
/// See [kSurahOpeningGap] for why the pair is not left as two.
class _SurahOpening extends StatelessWidget {
  const _SurahOpening({
    required this.header,
    required this.tailGap,
    this.basmala,
    this.openingGap = kSurahOpeningGap,
  });

  final Widget header;

  /// The heading basmala, or null for Al-Fatiha — the one surah that has none,
  /// because its basmala is verse 1 and the page draws it as an ordinary line.
  final Widget? basmala;

  /// Space under the opening, before the surah's first verse. Chosen by the
  /// caller: an ordinary surah, Al-Baqara's illuminated page, and Al-Fatiha's
  /// banner standing on its own each want a different amount.
  final double tailGap;

  /// Space between the banner and the basmala directly under it. Defaults to
  /// the printed [kSurahOpeningGap]; landscape sets it against the page's glyph
  /// size instead — see [kLandscapeOpeningGapEm].
  final double openingGap;

  @override
  Widget build(BuildContext context) {
    final basmala = this.basmala;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (basmala != null) ...[SizedBox(height: openingGap), basmala],
        SizedBox(height: tailGap),
      ],
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
