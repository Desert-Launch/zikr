import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/onboarding/presentation/widgets/w_check_circle.dart';

class LangOption {
  const LangOption({required this.code, required this.nativeName, required this.englishName, required this.flag});
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
}

class WLangTile extends StatelessWidget {
  const WLangTile({super.key, required this.opt, required this.selected, required this.onTap});

  final LangOption opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: context.brand.surface,
            border: Border.all(
              color: selected ? AppColorsLight.primary : context.brand.border,
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            gradient: LinearGradient(
              colors: [selected ? const Color.fromARGB(255, 200, 242, 226) : Colors.white, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              WCheckCircle(selected: selected),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.nativeName,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    opt.englishName,
                    style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
                  ),
                ],
              ),
              SizedBox(width: 14.w),

              Text(opt.flag, style: TextStyle(fontSize: 24.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
