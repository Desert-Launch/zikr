import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// A small muted section header above an adhan settings group.
class WAdhanSectionLabel extends StatelessWidget {
  const WAdhanSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Tablet pins a fixed 16 so every settings section label across the app
    // reads at the same size; `.sp` would inflate this to ~19 instead.
    final isTab = context.isTablet;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w, bottom: isTab ? 6 : 9.h),
      child: Text(
        text,
        style: AppTextStyles.grey12W400.copyWith(fontSize: isTab ? 16 : null),
      ),
    );
  }
}
