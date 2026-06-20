import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// A tappable "from/to" range row opening the mushaf at [pageNumber].
class WKhatmaRangeRow extends StatelessWidget {
  const WKhatmaRangeRow({super.key, required this.title, required this.subtitle, required this.pageNumber});

  final String title;
  final String subtitle;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(QuranRoutes.readerFromPage(pageNumber)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded, size: 30.r, color: const Color(0xFF6B6B6B)),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.ink16W400,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.grey12W400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
