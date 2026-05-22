import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Generic markdown viewer. Each legal screen passes the title and the
/// ar/en asset paths; this widget picks the matching one for the current
/// locale and renders it.
class WMarkdownScreen extends StatelessWidget {
  const WMarkdownScreen({
    super.key,
    required this.titleKey,
    required this.arAsset,
    required this.enAsset,
  });

  final String titleKey;
  final String arAsset;
  final String enAsset;

  @override
  Widget build(BuildContext context) {
    final isAr = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final asset = isAr ? arAsset : enAsset;
    return Scaffold(
      appBar: AppBar(
        title: Text(titleKey.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(
            data: snap.data!,
            padding: EdgeInsets.all(20.w),
            styleSheet: MarkdownStyleSheet(
              h1: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColorsLight.primaryDark,
              ),
              h2: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColorsLight.primary,
              ),
              p: TextStyle(fontSize: 14.sp, height: 1.7),
              listBullet: TextStyle(fontSize: 14.sp),
            ),
          );
        },
      ),
    );
  }
}
