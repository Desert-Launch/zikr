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
  const WMushafV4Page({required this.layout, super.key});

  final MQpcV4Page layout;

  @override
  State<WMushafV4Page> createState() => _WMushafV4PageState();
}

class _WMushafV4PageState extends State<WMushafV4Page> {
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
        Map<String, String?> bookmarks,
      })
    >(
      selector: (s) =>
          (selected: s.selectedAyah, theme: s.theme, mode: s.fontMode, fontScale: s.fontScale, bookmarks: s.bookmarks),
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
        final baseColor = isDark ? const Color(0xFFF2E9D8) : const Color(0xFF0A0A0A);
        final markerColor = isDark ? const Color(0xFFE9C46A) : AppColorsLight.primary;
        final muted = context.brand.muted;
        final headerColor = isDark ? Colors.white70 : muted;
        final brightness = isDark ? Brightness.dark : Brightness.light;

        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            final bigText = isBigTextScale(view.fontScale);
            final lineWidgets = _blockWidgets(
              context: context,
              cubit: cubit,
              bigText: bigText,
              selected: view.selected,
              playing: playing,
              bookmarks: view.bookmarks,
              fontFamily: fontFamily,
              baseColor: baseColor,
              markerColor: markerColor,
              brightness: brightness,
              fontScale: view.fontScale,
              isDark: isDark,
            );

            final isFullPage = widget.layout.blocks.length >= 12;
            // The openers (pp. 1–2) sit centred with spare vertical room, so add
            // breathing space between their lines.
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

            return Container(
              color: readerBackground(view.theme),
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WMushafPageHeader(surahName: _pageSurahName, page: page, color: headerColor),
                  // At 100% every line fits one row and the page fills exactly
                  // one screen — the ConstrainedBox keeps the lines distributed
                  // as before and nothing scrolls. Above 100% the lines wrap,
                  // the page outgrows the viewport, and it scrolls vertically.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            // Reflowed runs are already as tall as their text
                            // needs; distributing them would just push the
                            // stream apart, so big text stacks from the top.
                            mainAxisAlignment: bigText
                                ? MainAxisAlignment.start
                                : (isFullPage ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: wrapped,
                          ),
                        ),
                      ),
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
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required Color baseColor,
    required Color markerColor,
    required Brightness brightness,
    required double fontScale,
    required bool isDark,
  }) {
    final widgets = <Widget>[];
    final run = <MQpcV4LineBlock>[];

    void flushRun() {
      if (run.isEmpty) return;
      widgets.add(
        WMushafPageReflow(
          blocks: List<MQpcV4LineBlock>.of(run),
          selected: selected,
          playing: playing,
          bookmarks: bookmarks,
          fontFamily: fontFamily,
          baseColor: baseColor,
          markerColor: markerColor,
          brightness: brightness,
          fontScale: fontScale,
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
          widgets.add(_basmala(baseColor, fontScale));
        case MQpcV4LineBlock():
          if (bigText) {
            run.add(block);
          } else {
            widgets.add(
              WMushafLine(
                block: block,
                selected: selected,
                playing: playing,
                bookmarks: bookmarks,
                fontFamily: fontFamily,
                baseColor: baseColor,
                markerColor: markerColor,
                brightness: brightness,
                fontScale: fontScale,
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
      title: surah == null ? '' : (surah.arabicLong.isNotEmpty ? surah.arabicLong : surah.arabic),
      surahNumber: surah?.number ?? surahNumber,
      ayahCount: surah?.totalAyah,
      dark: dark,
    );
  }

  Widget _basmala(Color color, double fontScale) {
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
          style: GoogleFonts.amiri(fontSize: 26.sp * fontScale, color: color, height: 1.4),
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
