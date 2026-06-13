import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';

class WQiblaErrorState extends StatelessWidget {
  const WQiblaErrorState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64.r, color: context.brand.muted),
        SizedBox(height: 12.h),
        Text(title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: context.brand.muted)),
        if (retry != null) ...[
          SizedBox(height: 16.h),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text('common_retry'.tr()),
            onPressed: retry,
          ),
        ],
      ],
    );
  }
}
