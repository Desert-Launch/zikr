import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';

class WReciterTile extends StatelessWidget {
  const WReciterTile({
    required this.reciter,
    required this.isActive,
    required this.isPreviewing,
    required this.onTap,
    required this.onPreview,
    super.key,
  });

  final MReciter reciter;
  final bool isActive;
  final bool isPreviewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: isActive ? AppColors.brandPurple : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_rounded,
                    color: AppColors.brandPurple, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.arabic.isEmpty ? reciter.name : reciter.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cleanTextPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: reciter.style == ReciterStyle.mujawwad
                                ? AppColors.surfaceLightPurple
                                : AppColors.surfaceLightGreen,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            reciter.style == ReciterStyle.mujawwad ? 'مجود' : 'مرتل',
                            style: TextStyle(fontSize: 10.sp, color: AppColors.cleanTextSecondary),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '~${reciter.estimatedSizeMb} MB',
                          style: TextStyle(fontSize: 11.sp, color: AppColors.cleanTextTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.check_circle, color: AppColors.brandPurple),
                ),
              IconButton(
                icon: Icon(
                  isPreviewing ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                ),
                tooltip: 'reciter_picker_preview'.tr(),
                onPressed: onPreview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
