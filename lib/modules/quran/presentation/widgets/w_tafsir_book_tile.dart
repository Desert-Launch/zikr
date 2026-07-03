import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';

/// One catalogue row: book name + language, with a download / progress / delete
/// affordance on the trailing side.
class WTafsirBookTile extends StatelessWidget {
  const WTafsirBookTile({
    required this.book,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
    super.key,
  });

  final ETafsirBook book;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.brand.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(Icons.menu_book_rounded, size: 22.r, color: context.brand.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.brand.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(book.language, style: AppTextStyles.grey12W500),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _trailing(context),
          ],
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context) {
    if (isDownloading) {
      return SizedBox(
        width: 34.r,
        height: 34.r,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress <= 0 ? null : progress,
              strokeWidth: 2.5,
              color: context.brand.primary,
            ),
            Text(
              '${(progress * 100).round()}',
              style: TextStyle(fontSize: 9.sp, color: context.brand.muted),
            ),
          ],
        ),
      );
    }
    if (isDownloaded) {
      return IconButton(
        tooltip: 'tafsir_delete'.tr(),
        icon: Icon(Icons.delete_outline_rounded, color: context.brand.error),
        onPressed: onDelete,
      );
    }
    return IconButton(
      tooltip: 'tafsir_download'.tr(),
      icon: Icon(Icons.download_rounded, color: context.brand.primary),
      onPressed: onDownload,
    );
  }
}
