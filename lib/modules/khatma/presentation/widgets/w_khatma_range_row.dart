import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
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

/// A tappable "from/to" range row opening the mushaf at the given ayah
/// (highlighted), falling back to [pageNumber] when the surah is unresolved.
/// With a [wirdRange], the reader also keeps both ends of the wird tinted.
class WKhatmaRangeRow extends StatelessWidget {
  const WKhatmaRangeRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
    this.surahNumber = 0,
    this.ayahNumber = 0,
    this.wirdRange,
  });

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
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ink16W400,
                  ),
                  SizedBox(height: 2.h),
                  // Ayah text is Arabic regardless of the UI language.
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.grey12W400,
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
