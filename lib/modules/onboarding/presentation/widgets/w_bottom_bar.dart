import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_circle_button.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_onboarding_next_button.dart';

class WBottomBar extends StatelessWidget {
  const WBottomBar({
    super.key,
    required this.accent,
    required this.isLast,
    required this.showBack,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final Color accent;
  final bool isLast;
  final bool showBack;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkip,
            child: Text(
              'onboarding_skip'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: context.brand.muted,
              ),
            ),
          ),
          Row(
            children: [
              if (showBack) ...[
                WCircleButton(accent: accent, onTap: onBack),
                SizedBox(width: 12.w),
              ],
              WOnboardingNextButton(
                accent: accent,
                label: isLast
                    ? 'onboarding_get_started'.tr()
                    : 'onboarding_next'.tr(),
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
