import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';

/// Basmala line for surahs other than Al-Fatihah. Uses the QCF_BSML font so
/// the typography matches the rest of the QPC mushaf.
class WBasmalaLine extends StatelessWidget {
  const WBasmalaLine({this.fontSize, super.key});

  /// Optional override — when null, uses 28sp.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: DSQpcFontLoader.basmalaFamily,
            fontSize: fontSize ?? 28.sp,
            color: AppColors.cleanTextPrimary,
          ),
        ),
      ),
    );
  }
}
