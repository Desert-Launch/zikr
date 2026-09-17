import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_virtue_card.dart';

/// One page of the azkar pager: the zekr text up top, its virtue card resting
/// at the bottom, and the whole surface counting a tap.
///
/// The page is at least as tall as the viewport so the virtue card sits low on
/// short azkar, yet everything scrolls together once a long zekr (or a long
/// virtue) needs the room.
class WAzkarPlayerPage extends StatelessWidget {
  const WAzkarPlayerPage({super.key, required this.item, required this.gold, required this.onTap});

  final MAzkarItem item;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final virtue = item.virtueAr;
    final vertical = 24.h + 16.h;
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (constraints.maxHeight - vertical).clamp(0, double.infinity)),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.textAr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.ink24W400.copyWith(fontSize: 24.sp, height: 1.9),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (virtue != null && virtue.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: WAzkarVirtueCard(text: virtue, gold: gold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
