import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_icon_box.dart';

/// Full-width feature card: icon on the right, title + subtitle right-aligned.
class WHomeWideFeature extends StatelessWidget {
  const WHomeWideFeature({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.route,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Modular.to.pushNamed(route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: AppTextStyles.ink18W500),
                SizedBox(height: 2.h),
                if (sub != null) Text(sub, style: AppTextStyles.grey12W400),
              ],
            ),
            SizedBox(width: 12.w),
            WHomeIconBox(icon: icon, color: color),
          ],
        ),
      ),
    );
  }
}
