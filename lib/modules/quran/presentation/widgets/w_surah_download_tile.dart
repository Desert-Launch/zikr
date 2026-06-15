import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';

/// One surah row in the per-reciter download screen. The trailing affordance
/// reflects disk-truth status: download / complete-the-gaps / a live progress
/// ring / a green check with a delete option.
class WSurahDownloadTile extends StatelessWidget {
  const WSurahDownloadTile({
    required this.surah,
    required this.info,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
    super.key,
  });

  final MSurah surah;
  final SurahDownloadInfo info;

  /// Non-null while this surah is actively downloading.
  final SurahDownloadProgress? progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final downloading = progress != null;

    final String subtitle;
    if (downloading) {
      subtitle =
          '${progress!.onDisk}/${progress!.total} ${'quran_downloads_ayat_unit'.tr()}';
    } else if (info.status == ESurahDownloadStatus.partial) {
      subtitle =
          '${info.downloaded}/${info.total} ${'quran_downloads_ayat_unit'.tr()}';
    } else {
      subtitle = '${surah.totalAyah} ${'quran_downloads_ayat_unit'.tr()}';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: brand.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: brand.border),
        ),
        child: Row(
          children: [
            _NumberBadge(number: surah.number, brand: brand),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.arabic,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: brand.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.sp, color: brand.muted),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _trailing(context, brand, downloading),
          ],
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context, BrandColors brand, bool downloading) {
    if (downloading) {
      return SizedBox(
        width: 34.r,
        height: 34.r,
        child: CircularProgressIndicator(
          value: progress!.fraction == 0 ? null : progress!.fraction,
          strokeWidth: 3,
          color: brand.primary,
          backgroundColor: brand.primary.withValues(alpha: 0.15),
        ),
      );
    }
    switch (info.status) {
      case ESurahDownloadStatus.complete:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: brand.success, size: 22.r),
            IconButton(
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded, color: brand.muted, size: 20.r),
              tooltip: 'quran_downloads_delete'.tr(),
            ),
          ],
        );
      case ESurahDownloadStatus.partial:
        return _ActionButton(
          label: 'quran_downloads_complete_surah'.tr(),
          brand: brand,
          onTap: onDownload,
        );
      case ESurahDownloadStatus.none:
        return _ActionButton(
          label: 'quran_downloads_download_surah'.tr(),
          brand: brand,
          onTap: onDownload,
        );
    }
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.brand});
  final int number;
  final BrandColors brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.r,
      height: 32.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: brand.primary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.brand,
    required this.onTap,
  });
  final String label;
  final BrandColors brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: brand.primary,
        side: BorderSide(color: brand.primary),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
      icon: Icon(Icons.download_rounded, size: 16.r),
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }
}
