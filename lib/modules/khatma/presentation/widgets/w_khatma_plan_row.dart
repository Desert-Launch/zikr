import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

/// Compact list-tile row for a plan in the "all plans" list.
class WKhatmaPlanRow extends StatelessWidget {
  const WKhatmaPlanRow({super.key, required this.plan, required this.onTap});

  final MKhatmaMetadata plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return ListTile(
      dense: true,
      leading: const Icon(Icons.chevron_left_rounded, size: 18),
      title: Text(
        isArabic ? plan.nameAr : plan.nameEn,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 15.sp),
      ),
      subtitle: Text(
        isArabic ? plan.quartersPerDayAr : plan.quartersPerDayEn,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 12.sp),
      ),
      onTap: onTap,
    );
  }
}
