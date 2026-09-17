import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/utils/helper/date_labels.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_outline_circle.dart';

class WPrayerHeader extends StatelessWidget {
  const WPrayerHeader({super.key, required this.state, required this.green, required this.onRefresh});

  final SPrayerTimes state;
  final Color green;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      height: context.isTablet ? 190.h : 258.h,
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55.w,
            top: -70.h,
            child: WPrayerOutlineCircle(size: 160.r),
          ),
          Positioned(
            left: -55.w,
            bottom: -75.h,
            child: WPrayerOutlineCircle(size: 155.r),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Back on the leading edge, settings on the trailing edge —
                // ordered so it mirrors with the layout direction.
                Row(
                  children: [
                    IconButton(
                      onPressed: NavHelper.back,
                      icon: const WLocalizeRotation(
                        reverse: true,
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('prayer_title'.tr(), style: AppTextStyles.white22W500),
                        Text('prayer_header_subtitle'.tr(), style: AppTextStyles.white14W400),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Modular.to.pushNamed(AdhanRoutes.overview()),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 7.h),
                InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: onRefresh,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.85), size: 18.r),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            state.cityName.isNotEmpty ? state.cityName : 'prayer_location_unknown'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.white14W400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  // Weekday · Gregorian · Hijri on a single line. Stacked, the
                  // three ate a third of the header for information that reads
                  // fine in a row. Scaled down rather than ellipsed so a long
                  // Hijri month keeps all three legible instead of truncating
                  // the date.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateLabels.weekday(now), style: AppTextStyles.white12W400),
                        _dot,
                        Text(DateLabels.gregorian(now), style: AppTextStyles.white14W500),
                        _dot,
                        Text(DateLabels.hijri(now), style: AppTextStyles.white12W400),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Neutral separator between the three date parts. A middle dot rather than
  /// a slash or dash: it carries no direction, so it sits the same way in RTL
  /// and LTR.
  Widget get _dot => Padding(
    padding: EdgeInsets.symmetric(horizontal: 7.w),
    child: Text(
      '\u00B7',
      style: AppTextStyles.white12W400.copyWith(
        color: Colors.white.withValues(alpha: 0.45),
      ),
    ),
  );
}
