import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';

/// "I have read and agree" checkbox; the whole row is tappable.
class WPrivacyAcceptTile extends StatelessWidget {
  const WPrivacyAcceptTile({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColorsLight.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
            ),
            Expanded(
              child: Text(
                'onboarding_privacy_accept'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
