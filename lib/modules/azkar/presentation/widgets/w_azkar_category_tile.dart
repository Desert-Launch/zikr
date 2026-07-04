import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// A white row tile in the "other azkar" browser: category title and item count.
class WAzkarCategoryTile extends StatelessWidget {
  const WAzkarCategoryTile({super.key, required this.title, required this.count, required this.onTap});

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded, color: Colors.grey[400], size: 20.r),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: context.width * 0.61,
                  child: Text(title, textAlign: TextAlign.right, style: AppTextStyles.ink14W500, maxLines: 2),
                ),
                SizedBox(height: 3.h),
                Text('$count ${'azkar_items_suffix'.tr()}', style: AppTextStyles.grey12W400.copyWith(fontSize: 10.sp)),
              ],
            ),
            SizedBox(width: 12.w),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: const Color(0xFFFF0B68).withValues(alpha: 0.12),
              child: Text('📿', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
