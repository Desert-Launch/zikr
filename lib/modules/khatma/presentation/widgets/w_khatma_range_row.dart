import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_range.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

/// The stretch of mushaf [wird] covers, or null when either surah never
/// resolved and the wird can only be opened by page.
ParamAyahRange? wirdRangeOf(MKhatmaWird wird) {
  if (!wird.hasSurahNumbers) return null;
  return ParamAyahRange(
    start: ParamAyahRef(
      surah: wird.startSurahNumber,
      ayah: wird.startAyahNumber,
    ),
    end: ParamAyahRef(surah: wird.endSurahNumber, ayah: wird.endAyahNumber),
  );
}

/// A tappable start/end row of a wird, opening the mushaf at the given ayah
/// (highlighted), falling back to [pageNumber] when the surah is unresolved.
/// With a [wirdRange], the reader also keeps both ends of the wird tinted.
///
/// Each end is labelled in words — "بداية الورد" / "نهاية الورد" — on a badge
/// of its own colour, above a large surah-and-ayah line: a bare "من"/"إلى"
/// was too easy to miss for older readers.
class WKhatmaRangeRow extends StatelessWidget {
  const WKhatmaRangeRow({
    super.key,
    required this.isEnd,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
    this.surahNumber = 0,
    this.ayahNumber = 0,
    this.wirdRange,
  });

  /// Which end of the wird this row is — picks the badge.
  final bool isEnd;
  final String title;
  final String subtitle;
  final int pageNumber;
  final int surahNumber;
  final int ayahNumber;
  final ParamAyahRange? wirdRange;

  String get _route {
    if (surahNumber <= 0 || ayahNumber <= 0) {
      return QuranRoutes.readerFromPage(pageNumber);
    }
    final range = wirdRange;
    if (range == null) {
      return QuranRoutes.readerFromAyah(surahNumber, ayahNumber);
    }
    return QuranRoutes.readerForRange(
      range,
      focus: ParamAyahRef(surah: surahNumber, ayah: ayahNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(_route),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RangeBadge(isEnd: isEnd),
                  SizedBox(height: 10.h),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ink18W700,
                  ),
                  SizedBox(height: 4.h),
                  // Ayah text is Arabic regardless of the UI language.
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.grey14W400.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20.w),
            WLocalizeRotation(
              child: Icon(
                Icons.chevron_left_rounded,
                size: 30.r,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "بداية الورد" on brand green, "نهاية الورد" on gold — two solid colours and
/// two glyphs, so the ends tell apart at a glance and not by reading alone.
class _RangeBadge extends StatelessWidget {
  const _RangeBadge({required this.isEnd});

  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    // Ink on gold: white on it falls well short of a readable contrast.
    final foreground = isEnd ? AppColorsLight.onSurface : AppColorsLight.onPrimary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isEnd ? AppColorsLight.accent : AppColorsLight.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnd ? Icons.flag_rounded : Icons.play_arrow_rounded,
            size: 18.r,
            color: foreground,
          ),
          SizedBox(width: 6.w),
          Text(
            (isEnd ? 'khatma_wird_end' : 'khatma_wird_start').tr(),
            style: AppTextStyles.ink14W700.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
