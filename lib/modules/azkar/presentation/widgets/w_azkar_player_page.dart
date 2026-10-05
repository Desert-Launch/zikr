import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_virtue_card.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_zekr_text.dart';

/// One page of the azkar pager: the zekr text on a white card up top, its
/// virtue card resting at the bottom, and the whole surface counting a tap.
///
/// The page is at least as tall as the viewport so the virtue card sits low on
/// short azkar, yet everything scrolls together once a long zekr (or a long
/// virtue) needs the room.
class WAzkarPlayerPage extends StatelessWidget {
  const WAzkarPlayerPage({
    super.key,
    required this.item,
    required this.green,
    required this.gold,
    required this.onTap,
  });

  final MAzkarItem item;
  final Color green;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final language = LocalizeAndTranslate.getLanguageCode();
    final virtue = item.virtue(language);
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
                  _ZekrCard(green: green, child: WAzkarZekrText(text: item.text(language))),
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

/// The white sheet the zekr is read from: a soft lift off the canvas and a
/// faint ring in the corner echoing the one on the virtue card.
class _ZekrCard extends StatelessWidget {
  const _ZekrCard({required this.green, required this.child});

  final Color green;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22.r);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEDEBE4)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              top: -40.r,
              left: -36.r,
              child: Container(
                width: 110.r,
                height: 110.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: green.withValues(alpha: 0.07), width: 3),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 22.h),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
