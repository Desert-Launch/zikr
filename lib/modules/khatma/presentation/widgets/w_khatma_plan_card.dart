import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

/// Suggested-plan card shown on the khatma plans screen.
class WKhatmaPlanCard extends StatelessWidget {
  const WKhatmaPlanCard({
    super.key,
    required this.plan,
    required this.suggested,
    required this.onTap,
  });

  final MKhatmaMetadata plan;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFDDE6E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? plan.nameAr : plan.nameEn,
                  style: TextStyle(fontSize: 16.sp),
                ),
                Text(
                  isArabic ? plan.quartersPerDayAr : plan.quartersPerDayEn,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
