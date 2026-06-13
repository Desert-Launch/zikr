import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_header_circle.dart';

class WSettingsHeader extends StatelessWidget {
  const WSettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F7E63), Color(0xFF286B55)],
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            PositionedDirectional(
              top: -57.r,
              start: -13.r,
              child: const WSettingsHeaderCircle(size: 112),
            ),
            PositionedDirectional(
              bottom: -51.r,
              end: -24.r,
              child: const WSettingsHeaderCircle(size: 94),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(23.w, 10.h, 23.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Modular.to.pop,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'settings_title'.tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'settings_subtitle'.tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 11.sp,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
