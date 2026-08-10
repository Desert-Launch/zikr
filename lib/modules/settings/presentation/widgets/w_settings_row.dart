import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_icon.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row_value.dart';

class WSettingsRow extends StatelessWidget {
  const WSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.leading,
    this.onTap,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = leading;
    // On tablet the 780x844 design height stretches every `.h` by ~1.6x, which
    // leaves a 39px-tall row floating in 114px of empty space. Fixed logical
    // values keep the tablet rows as tight as they read on phones.
    final isTab = context.isTablet;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isTab ? 62 : 72.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: isTab ? 9 : 11.h),
          child: Row(
            children: [
              WSettingsIcon(icon: icon),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF303030),
                        fontSize: isTab ? 16 : 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isTab ? 3 : 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: isTab ? 11.5 : 9.sp,
                        color: const Color(0xFF858585),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (leadingWidget != null)
                leadingWidget
              else
                WSettingsRowValue(value: value, showChevron: showChevron),
            ],
          ),
        ),
      ),
    );
  }
}
