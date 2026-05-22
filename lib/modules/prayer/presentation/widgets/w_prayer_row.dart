import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

class WPrayerRow extends StatelessWidget {
  const WPrayerRow({
    super.key,
    required this.slot,
    required this.isNext,
    required this.isCurrent,
    required this.labelAr,
  });

  final PrayerSlot slot;
  final bool isNext;
  final bool isCurrent;
  final String labelAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight = isNext;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: highlight
            ? AppColorsLight.primary.withValues(alpha: 0.08)
            : cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: highlight ? AppColorsLight.primary : context.brand.border,
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(_iconFor(slot.prayer),
                color: AppColorsLight.primary, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labelAr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                    )),
                if (isCurrent)
                  Text('prayer_current_window'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.brand.muted,
                      )),
                if (isNext)
                  Text('prayer_next_label'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.w700,
                      )),
              ],
            ),
          ),
          Text(_format(slot.time),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColorsLight.primary : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }

  IconData _iconFor(EPrayer p) => switch (p) {
        EPrayer.fajr => Icons.brightness_3_rounded,
        EPrayer.sunrise => Icons.wb_twilight_rounded,
        EPrayer.dhuhr => Icons.wb_sunny_rounded,
        EPrayer.asr => Icons.wb_cloudy_rounded,
        EPrayer.maghrib => Icons.brightness_4_rounded,
        EPrayer.isha => Icons.brightness_2_rounded,
      };

  static String _format(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final suffix = dt.hour >= 12 ? 'م' : 'ص';
    return '${two(h)}:${two(dt.minute)} $suffix';
  }
}

