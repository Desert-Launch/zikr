import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';

class WQuranHeader extends StatelessWidget {
  const WQuranHeader({
    super.key,
    required this.cubit,
    required this.onBack,
    this.onSettings,
  });

  final CBSurahList cubit;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF007A58),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                if (onSettings != null)
                  IconButton(
                    onPressed: onSettings,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  )
                else
                  const SizedBox(width: 42),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      'app_name'.tr(),
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'quran_surah_total'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextField(
              onChanged: cubit.setQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11.sp,
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20.r,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
