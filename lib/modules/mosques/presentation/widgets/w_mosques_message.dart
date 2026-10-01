import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_app_button.dart';

/// Centered icon + explanation + one action, for the nearby-mosques screen's
/// empty and failure states.
class WMosquesMessage extends StatelessWidget {
  const WMosquesMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56.r, color: brand.muted.withValues(alpha: 0.6)),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.ink16W700.copyWith(color: brand.onSurface),
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.grey14W400.copyWith(color: brand.muted),
          ),
          SizedBox(height: 18.h),
          WAppButton(
            title: actionLabel,
            onTap: onAction,
            height: 44.h,
            withShadow: false,
            style: AppTextStyles.white14W500,
          ),
        ],
      ),
    );
  }
}
