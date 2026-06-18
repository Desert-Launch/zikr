import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

/// Active-plan summary card (completed/total + plan name) on the tracker screen.
class WKhatmaPlanSummaryCard extends StatelessWidget {
  const WKhatmaPlanSummaryCard({super.key, required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final metadata = state.metadata;
    if (metadata == null) return const SizedBox.shrink();
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Modular.to.pushNamed(KhatmaRoutes.fullWirds(metadata.id)),
      child: Container(
        height: 96.h,
        padding: EdgeInsetsDirectional.fromSTEB(24.w, 0, 24.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFDDE6E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left_rounded,
              size: 30.r,
              color: const Color(0xFF6B6B6B),
            ),
            SizedBox(width: 18.w),
            Text('${state.wirds.length}', style: AppTextStyles.grey18W400),
            const Spacer(),
            Text(
              isArabic ? metadata.nameAr : metadata.nameEn,
              textAlign: TextAlign.end,
              style: AppTextStyles.ink20W400,
            ),
          ],
        ),
      ),
    );
  }
}
