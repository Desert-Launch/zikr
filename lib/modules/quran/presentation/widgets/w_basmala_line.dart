import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';

/// Basmala line for surahs other than Al-Fatihah.
///
/// We reuse Al-Fatihah's basmala glyphs (`ﭑ ﭒ ﭓ ﭔ` = U+FB51..U+FB54) rendered
/// with the page-1 QPC font (`QCF_P1`) — this gives the exact same calligraphic
/// basmala typography across every standalone basmala line in the mushaf,
/// matching the printed Madani copy. The verse-end glyph U+FB55 is intentionally
/// excluded since these basmalas aren't ayah 1.
class WBasmalaLine extends StatefulWidget {
  const WBasmalaLine({this.fontSize, super.key});

  final double? fontSize;

  /// Glyph sequence for the QPC V1 basmala (no ayah-end marker).
  static const String basmalaGlyphs = 'ﭑ ﭒ ﭓ ﭔ';

  /// Font family used to render [basmalaGlyphs].
  static final String fontFamily = DSQpcFontLoader.pageFamily(1);

  @override
  State<WBasmalaLine> createState() => _WBasmalaLineState();
}

class _WBasmalaLineState extends State<WBasmalaLine> {
  @override
  void initState() {
    super.initState();
    // Make sure QCF_P1 is registered even when the reader hasn't loaded page 1.
    Modular.get<DSQpcFontLoader>().loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBMushafReader, SMushafReader, double>(
      selector: (s) => s.fontScale,
      builder: (context, scale) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Center(
            child: Text(
              WBasmalaLine.basmalaGlyphs,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: WBasmalaLine.fontFamily,
                fontSize: (widget.fontSize ?? 28.sp) * scale,
                color: AppColors.cleanTextPrimary,
                height: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
