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
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_basmala_line.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_header.dart';

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
    _fonts.preloadWindow(widget.layout.page);
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
    final pageFamily = DSQpcFontLoader.pageFamily(widget.layout.page);

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
        // QPC V1 glyphs have hair-thin strokes by design — keep the text in a
        // saturated near-black so they remain readable over the cream paper.
        // Theme.onSurface (#1A1A1A) is technically dark but loses contrast on
        // cream once anti-aliasing thins the strokes further.
        final fg = view.theme == ReaderTheme.dark
            ? Colors.white
            : const Color(0xFF0A0A0A);
        return BlocSelector<CBAudioPlayer, SAudioPlayer, ParamAyahRef?>(
          bloc: Modular.get<CBAudioPlayer>(),
          selector: (s) => s.currentAyah,
          builder: (context, playing) {
            final lineWidgets = widget.layout.lines
                .map((line) {
                  switch (line.type) {
                    case LineType.surahHeader:
                      final surah = _surahs[line.surahNumber];
                      return WSurahHeader(
                        title: line.text,
                        surahNumber: surah?.number ?? line.surahNumber,
                        ayahCount: surah?.totalAyah,
                        dark: view.theme == ReaderTheme.dark,
                      );
                    case LineType.basmala:
                      return WBasmalaLine(fontSize: 28.sp * view.scale);
                    case LineType.spacer:
                      return SizedBox(height: 8.h);
                    case LineType.text:
                      return _renderTextLine(
                        line,
                        cubit: cubit,
                        selected: view.selected,
                        playing: playing,
                        bookmarks: view.bookmarks,
                        fontFamily: pageFamily,
                        scale: view.scale,
                        color: fg,
                      );
                  }
                })
                .toList(growable: false);

            // Regular Mushaf pages have ~15 lines and should fill the page
            // top-to-bottom. Short pages (Fatihah, Baqarah opening, last few)
            // have fewer lines and should be centered as a block inside the
            // available space.
            final isFullPage = widget.layout.lines.length >= 12;
            final wrappedLines = lineWidgets
                .map(
                  (w) => w is WSurahHeader
                      ? w
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: w,
                        ),
                )
                .toList(growable: false);

            return Container(
              color: _bgFor(view.theme),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Center(
                    child: Text(
                      '${widget.layout.page}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.brand.muted,
                      ),
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

  Color _bgFor(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.light:
        return AppColors.paperWarm;
      case ReaderTheme.sepia:
        return AppColors.paperCream;
      case ReaderTheme.dark:
        return AppColors.darkBackground;
    }
  }

  Widget _renderTextLine(
    MLine line, {
    required CBMushafReader cubit,
    required ParamAyahRef? selected,
    required ParamAyahRef? playing,
    required Map<String, String?> bookmarks,
    required String fontFamily,
    required double scale,
    required Color color,
  }) {
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
      group.glyphs.add(w.qpcV1);
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
            color: isPlaying ? AppColorsLight.accent : color,
            fontWeight: FontWeight.w500,
            height: 1.0,
            // Priority: live selection → now-playing → saved bookmark colour.
            backgroundColor: isSelected
                ? AppColors.surfaceLightGreen
                : (isPlaying
                      ? AppColors.accentGoldAmber.withValues(alpha: 0.15)
                      : (isBookmarked
                            ? bookmarkHighlightFromHex(bookmarks[group.ref.key])
                            : null)),
          ),
        ),
      );
      if (i != groups.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }
}

class _AyahGroup {
  _AyahGroup({required this.ref}) : glyphs = <String>[];
  final ParamAyahRef ref;
  final List<String> glyphs;
}
