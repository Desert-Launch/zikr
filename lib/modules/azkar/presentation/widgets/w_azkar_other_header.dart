import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/core/widgets/w_search_field.dart';

/// Header for the "other azkar" category browser, showing the total number of
/// categories.
class WAzkarOtherHeader extends StatelessWidget {
  const WAzkarOtherHeader({
    super.key,
    required this.green,
    required this.categoryCount,
    required this.onBack,
    this.onQueryChanged,
  });

  final Color green;
  final int categoryCount;
  final VoidCallback onBack;

  /// When provided, a search field is shown under the title and filters the
  /// category list live.
  final ValueChanged<String>? onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _titleRow(),
            if (onQueryChanged != null) ...[
              SizedBox(height: 10.h),
              WSearchField.onColor(
                onChanged: onQueryChanged ?? (_) {},
                hint: 'azkar_other_search_hint'.tr(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const WLocalizeRotation(
            child: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'azkar_other_title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$categoryCount ${'azkar_categories'.tr()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        CircleAvatar(
          radius: 21.r,
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          child: const Text('🤲', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}
