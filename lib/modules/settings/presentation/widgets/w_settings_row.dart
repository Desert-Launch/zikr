import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 72.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 11.h),
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
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 9.sp,
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
