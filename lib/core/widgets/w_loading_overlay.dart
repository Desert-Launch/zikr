import 'dart:ui';

import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';

class WLoadingOverlay extends StatelessWidget {
  const WLoadingOverlay({
    super.key,
    this.message,
    this.show = false,
    this.inline = false,
    this.transparent = false,
    this.indicatorColor = AppColors.brandMain,
  });

  final bool show;
  final bool inline;
  final bool transparent;
  final String? message;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    final overlayColor = transparent
        ? Colors.transparent
        : AppColors.darkBodyBackground.withValues(alpha: inline ? 0.35 : 0.40);

    final blur = inline ? 4.0 : 0.0;

    final spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: indicatorColor, strokeWidth: 3),
        if (message != null) ...[
          SizedBox(height: 16.h),
          Text(
            message!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.lightForeground, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: overlayColor,
            borderRadius: inline ? BorderRadius.circular(16.rCapped(18)) : null,
          ),
          child: BackdropFilter(
            filter: blur == 0 ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Center(child: spinner),
          ),
        ),
      ),
    );
  }
}
