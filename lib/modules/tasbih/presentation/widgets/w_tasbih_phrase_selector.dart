import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';

class WTasbihPhraseSelector extends StatelessWidget {
  const WTasbihPhraseSelector({
    super.key,
    required this.selected,
    required this.phrases,
    required this.green,
    required this.onChanged,
  });

  final String selected;
  final List<String> phrases;
  final Color green;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: phrases.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, index) {
          final phrase = phrases[index];
          final active = phrase == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(23.r),
            onTap: () => onChanged(phrase),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: active ? green.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(23.r),
                border: Border.all(color: active ? green : const Color(0xFFE8E7E2)),
              ),
              child: Text(
                phrase,
                style: active
                    ? AppTextStyles.ink14W400.copyWith(color: green, fontWeight: FontWeight.w700)
                    : AppTextStyles.ink14W400,
              ),
            ),
          );
        },
      ),
    );
  }
}
