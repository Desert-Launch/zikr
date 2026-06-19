import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/s_daily_verse.dart';

/// Converts Western digits in [value] to Arabic-Indic glyphs (٠..٩).
String _toArabicDigits(int value) {
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buf = StringBuffer();
  for (final unit in '$value'.codeUnits) {
    buf.write(unit >= 0x30 && unit <= 0x39 ? eastern[unit - 0x30] : unit);
  }
  return buf.toString();
}

/// "Verse of the day": a deterministic random ayah pulled from the bundled
/// mushaf, refreshed once per calendar day, with the text flanked by the two
/// decorative ornaments and a surah/ayah caption underneath.
class WHomeVerseCard extends StatelessWidget {
  const WHomeVerseCard({super.key, required this.gold}) : verse = null, label = null, _static = false;

  /// A fixed verse rendered in the same gold card chrome — no [CBDailyVerse]
  /// dependency, not height-capped, and not tappable. Used to surface a
  /// specific ayah (e.g. the فاطر 29 virtue verse) outside the home dashboard.
  const WHomeVerseCard.staticVerse({super.key, required this.gold, required EDailyVerse this.verse, this.label})
    : _static = true;

  final Color gold;

  /// The verse to show. `null` means "use the daily-verse cubit".
  final EDailyVerse? verse;

  /// Overrides the small caption above the verse (defaults to the daily label).
  final String? label;

  final bool _static;

  @override
  Widget build(BuildContext context) {
    if (_static) return _card(context, verse);
    return BlocBuilder<CBDailyVerse, SDailyVerse>(
      bloc: Modular.get<CBDailyVerse>(),
      builder: (_, state) => _card(context, state.verse),
    );
  }

  Widget _card(BuildContext context, EDailyVerse? verse) {
    final body = Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 22.h),
      child: Column(
        mainAxisSize: _static ? MainAxisSize.min : MainAxisSize.max,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: gold,
            child: Icon(Icons.star_rounded, size: 20.r, color: Colors.white),
          ),
          SizedBox(height: 2.h),
          Text(label ?? 'home_verse_label'.tr(), style: AppTextStyles.grey12W400),
          if (_static) ...[
            SizedBox(height: 8.h),
            _verseText(verse, maxLines: null),
            SizedBox(height: 6.h),
          ] else
            Expanded(child: Center(child: _verseText(verse, maxLines: 2))),
          Text(_sourceLabel(verse), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.grey14W400),
        ],
      ),
    );

    final decorated = Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: gold, width: 1.2),
              borderRadius: BorderRadius.circular(12.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
              ),
              boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 5))],
            ),
          ),
        ),
        Positioned(
          top: 4.h,
          right: 5.w,
          child: Container(
            width: 86.r,
            height: 86.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha: 0.13), width: 6.r),
            ),
          ),
        ),
        if (_static) body else Positioned.fill(child: body),
      ],
    );

    if (_static) return decorated;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: verse == null
          ? null
          : () => Modular.to.pushNamed(QuranRoutes.readerFromAyah(verse.surahNumber, verse.ayah)),
      child: SizedBox(height: 154.h, child: decorated),
    );
  }

  /// The verse text wrapped with the start/end ornaments. Falls back to the
  /// bundled sample verse while the daily verse is still loading. A `null`
  /// [maxLines] lets the full ayah wrap (used by the static variant).
  Widget _verseText(EDailyVerse? verse, {required int? maxLines}) {
    final text = verse?.text ?? 'home_verse'.tr();
    WidgetSpan ornament(String asset) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Image.asset(asset, height: 15.sp),
      ),
    );

    return Text.rich(
      TextSpan(
        style: GoogleFonts.amiri(textStyle: AppTextStyles.ink18W400, height: 1.6),
        children: [
          if (maxLines != null) ornament('assets/images/verse_ornament_start.png'),
          TextSpan(text: text),
          if (maxLines != null) ornament('assets/images/verse_ornament_end.png'),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }

  /// Surah name + ayah number caption (Arabic-Indic digits in Arabic), or the
  /// bundled sample source while loading.
  String _sourceLabel(EDailyVerse? verse) {
    if (verse == null) return 'home_verse_source'.tr();
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final name = isArabic ? verse.surahArabicName : verse.surahName;
    final ayah = isArabic ? _toArabicDigits(verse.ayah) : '${verse.ayah}';
    return 'home_verse_source_fmt'.tr().replaceFirst('{{surah}}', name).replaceFirst('{{ayah}}', ayah);
  }
}
