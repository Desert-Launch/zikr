import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';

/// A reciter row on the download-manager list. Shows the reciter's names and a
/// disk-derived stats line (style · completed surahs · size on disk).
class WReciterCard extends StatelessWidget {
  const WReciterCard({
    required this.reciter,
    required this.stats,
    required this.onTap,
    super.key,
  });

  final MReciter reciter;
  final ReciterStats? stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = stats;
    final styleLabel =
        (reciter.style == ReciterStyle.mujawwad
                ? 'reciter_style_mujawwad'
                : 'reciter_style_murattal')
            .tr();
    final done = s?.downloadedSurahs ?? 0;
    final totalSurahs = s?.totalSurahs ?? 114;
    final parts = <String>[
      styleLabel,
      '$done/$totalSurahs ${'quran_downloads_surahs_unit'.tr()}',
      if (s != null && s.totalBytes > 0)
        '${s.megabytes.toStringAsFixed(0)} ${'quran_downloads_mb'.tr()}',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: Material(
        color: brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: brand.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: brand.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: brand.primary,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reciter.arabic.isEmpty ? reciter.name : reciter.arabic,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: brand.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        reciter.name,
                        style: TextStyle(fontSize: 11.sp, color: brand.muted),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        parts.join(' · '),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: brand.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: brand.muted, size: 24.r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
