import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';

/// Virtue/verse card on the empty khatma screen.
class WKhatmaVirtueCard extends StatelessWidget {
  const WKhatmaVirtueCard({super.key, required this.title, required this.verse, required this.reference});

  final String title;
  final String verse;
  final String reference;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD6A72C);
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EBCB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: gold.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          colors: [Color(0xffF4E5C2), Color(0xffE8D7B0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 26.r),
          ),
          SizedBox(height: 10.h),
          Text(title, style: AppTextStyles.grey12W400),
          SizedBox(height: 8.h),
          Container(width: 60.w, height: 1, color: gold.withValues(alpha: 0.4)),
          SizedBox(height: 12.h),
          _verseText(EDailyVerse(text: verse, ayah: 0, surahArabicName: '', surahName: '', surahNumber: 0)),
          SizedBox(height: 10.h),
          Container(width: 60.w, height: 1, color: gold.withValues(alpha: 0.4)),
          SizedBox(height: 10.h),
          Text(reference, style: AppTextStyles.grey12W400),
        ],
      ),
    );
  }

  Widget _verseText(EDailyVerse? verse) {
    final text = verse?.text ?? 'home_verse'.tr();
    WidgetSpan ornament(String asset) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Image.asset(asset, height: 24.sp),
      ),
    );

    return Text.rich(
      TextSpan(
        style: GoogleFonts.amiri(textStyle: AppTextStyles.ink16W400, height: 1.6),
        children: [
          ornament('assets/images/verse_ornament_end.png'),
          TextSpan(text: text),
          ornament('assets/images/verse_ornament_start.png'),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
