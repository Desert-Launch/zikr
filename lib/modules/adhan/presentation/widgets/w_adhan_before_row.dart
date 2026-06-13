import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// The standalone "alert before adhan" row on the voice picker, cycling the
/// pre-notify minutes on tap.
class WAdhanBeforeRow extends StatelessWidget {
  const WAdhanBeforeRow({super.key, required this.state, required this.cubit});

  final SAdhanSettings state;
  final CBAdhanSettings cubit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(19.r),
      onTap: () {
        final next = switch (state.preNotifyMinutes) {
          0 => 5,
          5 => 10,
          10 => 15,
          _ => 0,
        };
        cubit.setPreNotifyMinutes(next);
      },
      child: Container(
        height: 76.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(color: const Color(0xFFE2ECE8)),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 3, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const WAdhanIconCircle(icon: Icons.notifications_none_rounded),
            SizedBox(width: 13.w),
            Text(
              'adhan_before_alert'.tr(),
              style: GoogleFonts.cairo(fontSize: 14.sp, color: const Color(0xFF303030)),
            ),
            const Spacer(),
            Text(
              state.preNotifyMinutes == 0
                  ? 'adhan_off'.tr()
                  : 'adhan_prenotify_minutes'.tr().replaceFirst('{{m}}', '${state.preNotifyMinutes}'),
              style: GoogleFonts.cairo(fontSize: 9.sp, color: const Color(0xFF777777)),
            ),
            Icon(Icons.chevron_left_rounded, color: const Color(0xFF777777), size: 21.r),
          ],
        ),
      ),
    );
  }
}
