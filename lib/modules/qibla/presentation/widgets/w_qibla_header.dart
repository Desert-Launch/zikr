import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class WQiblaHeader extends StatelessWidget {
  const WQiblaHeader({
    super.key,
    required this.city,
    required this.green,
    required this.greenLight,
  });

  final String? city;
  final Color green;
  final Color greenLight;

  @override
  Widget build(BuildContext context) {
    final currentCity = city;
    final subtitle = (currentCity != null && currentCity.isNotEmpty)
        ? currentCity
        : 'qibla_title'.tr();
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [greenLight, green],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: Modular.to.pop,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'home_qibla'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
