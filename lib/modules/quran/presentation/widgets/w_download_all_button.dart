import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Header action that downloads (or cancels downloading) every surah for the
/// current reciter.
class WDownloadAllButton extends StatelessWidget {
  const WDownloadAllButton({
    required this.isDownloadingAll,
    required this.currentSurah,
    required this.onDownloadAll,
    required this.onCancel,
    super.key,
  });

  final bool isDownloadingAll;
  final int currentSurah;
  final VoidCallback onDownloadAll;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    if (isDownloadingAll) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: brand.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: brand.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18.r,
              height: 18.r,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: brand.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '${'quran_downloads_downloading_all'.tr()} ($currentSurah/114)',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: brand.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: brand.error),
              child: Text('quran_downloads_cancel'.tr()),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onDownloadAll,
        style: ElevatedButton.styleFrom(
          backgroundColor: brand.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        icon: Icon(Icons.download_for_offline_rounded, size: 20.r),
        label: Text(
          'quran_downloads_download_all'.tr(),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
