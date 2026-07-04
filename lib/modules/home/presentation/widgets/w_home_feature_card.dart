import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_icon_box.dart';

/// Square-ish grid tile: icon top-right, title + subtitle bottom, right-aligned.
class WHomeFeatureCard extends StatelessWidget {
  const WHomeFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.route,
    this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  /// Route pushed on tap. Ignored when [onTap] is supplied.
  final String? route;

  /// Overrides the default route push — e.g. to open a picker sheet instead.
  final VoidCallback? onTap;

  VoidCallback? get _handleTap {
    if (onTap != null) return onTap;
    final r = route;
    if (r != null) return () => Modular.to.pushNamed(r);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: _handleTap,
      child: Container(
        height: 150.h,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            WHomeIconBox(icon: icon, color: color),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.ink18W500),
            SizedBox(height: 2.h),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.grey12W400),
          ],
        ),
      ),
    );
  }
}
