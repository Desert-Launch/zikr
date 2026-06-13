import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: phrases.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 2.75,
      ),
      itemBuilder: (_, index) {
        final phrase = phrases[index];
        final active = phrase == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: () => onChanged(phrase),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? green.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: active ? Border.all(color: green) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phrase,
                  style: GoogleFonts.amiri(
                    color: active ? green : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (active)
                  Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
