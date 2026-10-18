import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// The gold virtue card under a counter.
///
/// [bodyKey]'s text may hold several sections, one per paragraph (split on a
/// blank line); a paragraph of more than one line opens with its heading. A
/// single-line body — the tasbih virtue — has no heading and reads as one
/// centred paragraph.
class WTasbihVirtueCard extends StatelessWidget {
  const WTasbihVirtueCard({
    super.key,
    required this.gold,
    this.titleKey = 'tasbih_virtue_title',
    this.bodyKey = 'tasbih_virtue_body',
    this.sourceKey = 'tasbih_virtue_source',
  });

  final Color gold;
  final String titleKey;
  final String bodyKey;

  /// The narrator line under the body; null when the body carries its own
  /// verification section, as the salawat one does.
  final String? sourceKey;

  static List<({String? heading, String body})> _sections(String text) => [
    for (final paragraph in text.split('\n\n'))
      if (paragraph.trim().isNotEmpty) _section(paragraph.trim()),
  ];

  static ({String? heading, String body}) _section(String paragraph) {
    final lines = paragraph.split('\n').map((l) => l.trim()).toList();
    if (lines.length == 1) return (heading: null, body: paragraph);
    return (heading: lines.first, body: lines.skip(1).join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDC0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: gold),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: -35.h,
            end: -30.w,
            child: Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold.withValues(alpha: 0.15), width: 3),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15.r),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: gold,
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 20.sp),
                ),
                SizedBox(height: 5.h),
                Text(titleKey.tr(), style: AppTextStyles.grey12W400),
                for (final (i, section) in _sections(bodyKey.tr()).indexed) ...[
                  SizedBox(height: i == 0 ? 7.h : 16.h),
                  if (section.heading case final heading?) ...[
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ink14W700.copyWith(color: AppColorsLight.primary),
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Text(
                    section.body,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.ink16W400.copyWith(height: 1.7),
                  ),
                ],
                if (sourceKey case final source?) ...[
                  SizedBox(height: 5.h),
                  Text(source.tr(), style: AppTextStyles.grey12W400),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
