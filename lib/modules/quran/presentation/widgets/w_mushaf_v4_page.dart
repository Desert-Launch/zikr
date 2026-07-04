import 'package:flutter/gestures.dart';
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
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';

/// Renders one Mushaf page from its [MQpcV4Page] using the QPC-V4 colour fonts.
///
/// This is the single reader render path: tajweed is baked into the per-page
/// colour font (`fontMode == tajweedV4`), or collapsed to a plain uniform colour
/// (`plainV2`). Ayahs are grouped so tapping any word selects the whole ayah,
/// and selection / now-playing / bookmark tints are painted behind the glyphs by
/// [WAyahHighlightText]. Layout mirrors the printed Madani page: each line fits
/// the page width and the page fills one screen.
class WMushafV4Page extends StatefulWidget {
  const WMushafV4Page({required this.layout, super.key});

  final MQpcV4Page layout;

  @override
  State<WMushafV4Page> createState() => _WMushafV4PageState();
}

class _WMushafV4PageState extends State<WMushafV4Page> {
  final List<TapGestureRecognizer> _recognizers = [];
  late final DSQpcV4FontLoader _fonts = Modular.get<DSQpcV4FontLoader>();
  Map<int, MSurah> _surahs = const {};

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
    final page = widget.layout.page;

    return BlocSelector<
        CBMushafReader,
        SMushafReader,
        ({
          ParamAyahRef? selected,
          ReaderTheme theme,
          EQuranFontMode mode,
          Map<String, String?> bookmarks
        })>(
      selector: (s) => (
        selected: s.selectedAyah,
        theme: s.theme,
        mode: s.fontMode,
        bookmarks: s.bookmarks,
      ),
      builder: (context, view) {
        final isDark = view.theme == ReaderTheme.dark;
        final tajweed = view.mode == EQuranFontMode.tajweedV4;

        if (!_fonts.isPageReady(page) || widget.layout.blocks.isEmpty) {
          return Container(
            color: readerBackground(view.theme),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final fontFamily = _fonts.familyFor(page, dark: isDark, tajweed: tajweed);
        final baseColor =
            isDark ? const Color(0xFFF2E9D8) : const Color(0xFF0A0A0A);
        final markerColor = isDark ? const Color(0xFFE9C46A) : AppColorsLight.primary;
        final muted = context.brand.muted;
        final headerColor = isDark ? Colors.white70 : muted;
        final brightness = isDark ? Brightness.dark : Brightness.light;

        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            // Build each block; text lines carry their own highlight ranges.
            final lineWidgets = widget.layout.blocks.map((block) {
              if (block is MQpcV4SurahHeaderBlock) {
                return _surahHeader(block.surahNumber, dark: isDark);
              }
              if (block is MQpcV4BasmalaBlock) {
                return _basmala(baseColor);
              }
              if (block is MQpcV4LineBlock) {
                return _renderTextLine(
                  block,
                  cubit: cubit,
                  selected: view.selected,
                  playing: playing,
                  bookmarks: view.bookmarks,
                  fontFamily: fontFamily,
                  baseColor: baseColor,
                  markerColor: markerColor,
                  brightness: brightness,
                );
              }
              return const SizedBox.shrink();
            }).toList(growable: false);

            final isFullPage = widget.layout.blocks.length >= 12;
            // The openers (pp. 1–2) sit centred with spare vertical room, so add
            // breathing space between their lines.
            final openerGap = page <= 2 ? 7.h : 0.0;
            final wrapped = lineWidgets.map((w) {
              if (w is WSurahHeader) return w;
              final fitted =
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: w);
              return openerGap > 0
                  ? Padding(padding: EdgeInsets.symmetric(vertical: openerGap), child: fitted)
                  : fitted;
            }).toList(growable: false);

            return Container(
              color: readerBackground(view.theme),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WMushafPageHeader(
                    surahName: _pageSurahName,
                    page: page,
                    color: headerColor,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: isFullPage
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: wrapped,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      '$page',
                      style: TextStyle(fontSize: 11.sp, color: muted),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Widget _basmala(Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(fontSize: 26.sp, color: color, height: 1.4),
      ),
    );
  }

  /// One printed line: a single [WAyahHighlightText] whose highlight ranges track
  /// the selected / now-playing / bookmarked ayahs on the line.
  Widget _renderTextLine(
    MQpcV4LineBlock block, {
    required CBMushafReader cubit,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required Color baseColor,
    required Color markerColor,
    required Brightness brightness,
  }) {
    final glyphStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.sp,
      height: 1.0,
      color: baseColor,
      fontWeight: FontWeight.w500,
    );
    final markerStyle = TextStyle(
      fontFamily: 'ayahNumberV4',
      fontSize: 28.sp,
      height: 1.0,
      color: markerColor,
    );

    // Group consecutive segments by ayah so the whole ayah shares a recognizer
    // and one highlight range.
    final groups = <_AyahGroup>[];
    _AyahGroup? current;
    for (final seg in block.segments) {
      final ref = ParamAyahRef(surah: seg.surah, ayah: seg.ayah);
      if (current == null || current.ref.key != ref.key) {
        current = _AyahGroup(ref: ref);
        groups.add(current);
      }
      current.segments.add(seg);
    }

    final spans = <InlineSpan>[];
    final highlights = <AyahHighlight>[];
    var offset = 0;
    for (final group in groups) {
      final glyphText = group.segments.map((s) => s.glyphs).join();
      MQpcV4Segment? endSeg;
      for (final s in group.segments) {
        if (s.isAyahEnd) {
          endSeg = s;
          break;
        }
      }

      // The tap recognizer must sit on the leaf text spans, not a parent: hit
      // testing resolves a tap to the deepest span at that offset, so a parent
      // with only `children` never receives the tap. Each leaf of the ayah gets
      // its own recognizer for the same ref, so tapping any word (or its rosette)
      // selects the whole ayah.
      final children = <InlineSpan>[
        TextSpan(
          text: glyphText,
          style: glyphStyle,
          recognizer: _recogniser(group.ref, cubit),
        ),
      ];
      var len = glyphText.length;
      if (endSeg != null) {
        final markerText = '${_arabicDigits(endSeg.ayah)}\u202F\u202F';
        children.add(TextSpan(
          text: markerText,
          style: markerStyle,
          recognizer: _recogniser(group.ref, cubit),
        ));
        len += markerText.length;
      }

      final tint = _selectionColor(
        isSelected: selected?.key == group.ref.key,
        isPlaying: playing?.key == group.ref.key,
        bookmarkHex: bookmarks[group.ref.key],
        hasBookmark: bookmarks.containsKey(group.ref.key),
        brightness: brightness,
      );
      if (tint != null) {
        highlights.add(AyahHighlight(start: offset, end: offset + len, color: tint));
      }

      spans.add(TextSpan(children: children));
      offset += len;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: WAyahHighlightText(
        text: TextSpan(children: spans),
        ranges: highlights,
        // Grow the pill above/below the glyphs without touching line height.
        pad: 28.sp * 0.36,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Selection/playback/bookmark tint for an ayah, by priority: live selection →
  /// now-playing → saved bookmark colour. `null` when none apply.
  Color? _selectionColor({
    required bool isSelected,
    required bool isPlaying,
    required String? bookmarkHex,
    required bool hasBookmark,
    required Brightness brightness,
  }) {
    if (isSelected) {
      return brightness == Brightness.dark
          ? AppColors.surfaceLightGreen.withValues(alpha: 0.22)
          : AppColors.surfaceLightGreen;
    }
    if (isPlaying) return AppColors.accentGoldAmber.withValues(alpha: 0.15);
    if (hasBookmark) return bookmarkHighlightFromHex(bookmarkHex);
    return null;
  }
}

/// Reading-surface colour for [theme]. The QPC-V4 colour fonts carry a dark
/// variant, so tajweed no longer needs to be locked to a light page.
Color readerBackground(ReaderTheme theme) {
  switch (theme) {
    case ReaderTheme.light:
      return AppColors.paperWarm;
    case ReaderTheme.sepia:
      return AppColors.paperCream;
    case ReaderTheme.dark:
      return AppColors.darkBackground;
  }
}

String _arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

class _AyahGroup {
  _AyahGroup({required this.ref}) : segments = <MQpcV4Segment>[];
  final ParamAyahRef ref;
  final List<MQpcV4Segment> segments;
}
