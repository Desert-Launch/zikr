import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
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
      height: 325.h,
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Modular.to.pushNamed(AdhanRoutes.notificationsScreen()),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('prayer_title'.tr(), style: AppTextStyles.white22W500),
                        Text('prayer_header_subtitle'.tr(), style: AppTextStyles.white14W400),
                      ],
                    ),
                    SizedBox(width: 7.w),
                    IconButton(
                      onPressed: Modular.to.pop,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          state.cityName.isNotEmpty ? state.cityName : 'prayer_location_unknown'.tr(),
                          style: AppTextStyles.white14W400,
                        ),
                        SizedBox(width: 5.w),
                        Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.85), size: 18.r),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    children: [
                      Text(_weekday(now), style: AppTextStyles.white14W400),
                      SizedBox(height: 8.h),
                      Text(_date(now), style: AppTextStyles.white20W500),
                      SizedBox(height: 14.h),
                      Text(_hijriDate(now), style: AppTextStyles.white14W400),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime date) {
    const ar = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return LocalizeAndTranslate.getLanguageCode() == 'ar' ? ar[date.weekday - 1] : en[date.weekday - 1];
  }

  String _date(DateTime date) {
    const arMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = LocalizeAndTranslate.getLanguageCode() == 'ar' ? arMonths[date.month - 1] : enMonths[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  String _hijriDate(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + (12 * a) - 3;
    final julianDay = date.day + ((153 * m + 2) ~/ 5) + (365 * y) + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;

    var l = julianDay - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - (10631 * n) + 354;
    final j = (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) + ((l ~/ 5670) * ((43 * l) ~/ 15238));
    l = l - (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) - ((j ~/ 16) * ((15238 * j) ~/ 43)) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - ((709 * month) ~/ 24);
    final year = (30 * n) + j - 30;

    const arMonths = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    const enMonths = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Shaaban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qidah',
      'Dhu al-Hijjah',
    ];
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final monthName = isArabic ? arMonths[month - 1] : enMonths[month - 1];
    return isArabic ? '$day $monthName $year هـ' : '$day $monthName $year AH';
  }
}
