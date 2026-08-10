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
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

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
    if (_static) return _card(context, verse, loading: false);
    return BlocBuilder<CBDailyVerse, SDailyVerse>(
      bloc: Modular.get<CBDailyVerse>(),
      builder: (_, state) => _card(context, state.verse, loading: state.status == LoadStatus.loading),
    );
  }

  /// Floor for the daily card so a one-line ayah still reads as a card rather
  /// than a strip. It is a MINIMUM, never a fixed height: the card was pinned
  /// to this and a two-line verse needs about 169.h, so the second line was
  /// laid out and then sliced through the middle of its glyphs.
  static double get _minHeight => 154;

  Widget _card(BuildContext context, EDailyVerse? verse, {required bool loading}) {
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      child: Column(
        // Always min: the column asks for the height its text actually needs
        // and the card grows to it, instead of the text being squeezed into
        // whatever the card had left over.
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: gold,
            child: Icon(Icons.star_rounded, size: 20.r, color: Colors.white),
          ),
          SizedBox(height: 2.h),
          Text(label ?? 'home_verse_label'.tr(), style: AppTextStyles.grey12W400),
          SizedBox(height: 8.h),
          _verseText(verse, maxLines: _static ? null : 2),
          SizedBox(height: 8.h),
          Text(_sourceLabel(verse), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.grey14W400),
        ],
      ),
    );

    // The daily card keeps a floor and centres inside it; the static one is
    // free to be exactly as tall as its (uncapped) ayah.
    final content = _static
        ? body
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: _minHeight.h),
            child: Center(child: body),
          );

    final decorated = DecoratedBox(
      // The shadow lives out here, outside the clip — inside it the ClipRRect
      // would cut it off at the card's own edge and erase it.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: ClipRRect(
        // Keeps the decorative ring inside the rounded corner instead of
        // letting it paint across the gold border.
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: gold, width: 1.2),
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF6DE), Color(0xFFF4DDA8)],
                  ),
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
            // Sizes the Stack — everything else is positioned around it.
            content,
            // Manual "another verse" control — always on the side opposite the
            // decorative circle, so it never sits on top of it in either direction.
            if (!_static) Positioned(top: 4.h, left: 4.w, child: _refreshButton(loading)),
          ],
        ),
      ),
    );

    if (_static) return decorated;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: verse == null
          ? null
          : () => Modular.to.pushNamed(QuranRoutes.readerFromAyah(verse.surahNumber, verse.ayah)),
      child: decorated,
    );
  }

  /// Small circular button that swaps the card for another ayah. Shows a
  /// spinner instead of the icon while the next verse is being resolved.
  Widget _refreshButton(bool loading) {
    return Tooltip(
      message: 'home_verse_refresh'.tr(),
      child: InkResponse(
        radius: 20.r,
        onTap: loading ? null : Modular.get<CBDailyVerse>().next,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: SizedBox(
            width: 20.r,
            height: 20.r,
            child: loading
                ? CircularProgressIndicator(strokeWidth: 2, color: gold)
                : Icon(Icons.refresh_rounded, size: 20.r, color: gold),
          ),
        ),
      ),
    );
  }

  /// The verse text wrapped with the start/end ornaments. Falls back to the
  /// bundled sample verse while the daily verse is still loading. A `null`
  /// [maxLines] lets the full ayah wrap (used by the static variant).
  ///
  /// The ornaments are U+FD3E/U+FD3F ORNATE PARENTHESIS — the characters Arabic
  /// typography uses to frame a quoted ayah — rather than images. The PNGs that
  /// were here had been flattened onto an opaque beige, so each one painted a
  /// small dull rectangle over the card's gradient. Glyphs also scale with the
  /// text and take the card's gold, which a fixed-height bitmap cannot.
  Widget _verseText(EDailyVerse? verse, {required int? maxLines}) {
    final text = verse?.text ?? 'home_verse'.tr();
    final ornamentStyle = TextStyle(color: gold, fontSize: 20.sp);

    return Text.rich(
      TextSpan(
        style: GoogleFonts.amiri(textStyle: AppTextStyles.ink18W400, height: 1.6),
        children: [
          // Neither character is bidi-mirrored, so each renders exactly as its
          // name says. In RTL the logically-first span sits on the RIGHT, which
          // is where U+FD3F ORNATE RIGHT PARENTHESIS belongs; U+FD3E closes on
          // the left. Swapping them turns both brackets the wrong way round.
          if (maxLines != null) TextSpan(text: '﴿ ', style: ornamentStyle),
          TextSpan(text: text),
          if (maxLines != null) TextSpan(text: ' ﴾', style: ornamentStyle),
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
