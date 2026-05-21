import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';

class SNSplash extends StatefulWidget {
  const SNSplash({super.key});

  @override
  State<SNSplash> createState() => _SNSplashState();
}

class _SNSplashState extends State<SNSplash> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigateAfterDelay());
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Modular.to.navigate(QuranRoutes.fullSurahList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 96.r, color: AppColors.brandPurple),
            SizedBox(height: 24.h),
            Text(
              'القرآن الكريم',
              style: GoogleFonts.amiri(
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurpleDark,
              ),
            ),
            SizedBox(height: 32.h),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
