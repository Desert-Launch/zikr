import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_before_sheet.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// The standalone "alert before adhan" row on the voice picker. Tapping opens
/// a bottom sheet to pick the pre-notify minutes (presets or a custom value).
class WAdhanBeforeRow extends StatelessWidget {
  const WAdhanBeforeRow({
    super.key,
    required this.prayerKey,
    required this.state,
    required this.cubit,
  });

  final String prayerKey;
  final SAdhanSettings state;
  final CBAdhanSettings cubit;

  @override
  Widget build(BuildContext context) {
    final minutes = state.preNotifyMinutesPerPrayer[prayerKey] ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(19.r),
      onTap: () => WAdhanBeforeSheet.show(context, prayerKey, cubit),
      child: Container(
        height: 76.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(color: const Color(0xFFE2ECE8)),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 3, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            const WAdhanIconCircle(icon: Icons.notifications_none_rounded),
            SizedBox(width: 13.w),
            Text('adhan_before_alert'.tr(), style: AppTextStyles.ink12W400),
            const Spacer(),
            Text(
              minutes == 0
                  ? 'adhan_off'.tr()
                  : 'adhan_prenotify_minutes'.tr().replaceFirst('{{m}}', '$minutes'),
              style: GoogleFonts.cairo(fontSize: 9.sp, color: const Color(0xFF777777)),
            ),
          ],
        ),
      ),
    );
  }
}
