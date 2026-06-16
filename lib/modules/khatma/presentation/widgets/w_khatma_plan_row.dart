import 'package:flutter/material.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

/// Compact list-tile row for a plan in the "all plans" list.
class WKhatmaPlanRow extends StatelessWidget {
  const WKhatmaPlanRow({super.key, required this.plan, required this.onTap});

  final MKhatmaMetadata plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.chevron_left_rounded),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isArabic ? plan.nameAr : plan.nameEn, style: AppTextStyles.ink16W400),
              Text(isArabic ? plan.quartersPerDayAr : plan.quartersPerDayEn, style: AppTextStyles.grey12W400),
            ],
          ),
        ],
      ),
    );
  }
}
