import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// The white control bar pinned under the azkar pager:
/// previous · play · counter ring · reset · next.
///
/// The row inherits the ambient direction, so in Arabic "previous" lands on
/// the right edge; the chevrons are mirrored icons and follow it.
class WAzkarPlayerBar extends StatelessWidget {
  const WAzkarPlayerBar({
    super.key,
    required this.completed,
    required this.total,
    required this.green,
    required this.onTap,
    required this.onReset,
    required this.onPrevious,
    required this.onNext,
    this.onPlay,
  });

  final int completed;
  final int total;
  final Color green;

  /// Tapping the counter ring counts, same as tapping the page.
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// No-op while null — azkar have no audio to play yet.
  final VoidCallback? onPlay;

  static const _ink = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          // Phone-width controls even on a tablet — spreading five buttons
          // across 800dp leaves the ring stranded in the middle.
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundButton.filled(green: green, icon: Icons.arrow_back_ios_new_rounded, onTap: onPrevious),
                  _RoundButton.soft(icon: Icons.play_arrow_rounded, iconColor: green, iconSize: 26, onTap: onPlay),
                  _CounterRing(completed: completed, total: total, green: green, onTap: onTap),
                  _RoundButton.soft(icon: Icons.replay_rounded, iconColor: _ink, iconSize: 22, onTap: onReset),
                  _RoundButton.filled(green: green, icon: Icons.arrow_forward_ios_rounded, onTap: onNext),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The big ring in the middle: count, "of N", and a progress pill at the foot.
class _CounterRing extends StatelessWidget {
  const _CounterRing({required this.completed, required this.total, required this.green, required this.onTap});

  final int completed;
  final int total;
  final Color green;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (completed / total).clamp(0, 1).toDouble();
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 78.r,
        height: 78.r,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: green, width: 3),
          boxShadow: [BoxShadow(color: green.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completed',
                  style: AppTextStyles.ink24W700.copyWith(fontSize: 21.sp, height: 1.1),
                ),
                Text(
                  '${'azkar_of'.tr()} $total',
                  style: AppTextStyles.grey12W400.copyWith(fontSize: 10.sp, height: 1.1),
                ),
              ],
            ),
            Positioned(
              bottom: 8.r,
              child: SizedBox(
                width: 28.r,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    minHeight: 4.r,
                    value: progress,
                    color: green,
                    backgroundColor: const Color(0xFFE3E3E0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 44dp circular button — solid green for prev/next, soft grey for the rest.
class _RoundButton extends StatelessWidget {
  const _RoundButton.filled({required Color green, required this.icon, required this.onTap})
    : filled = true,
      fill = green,
      iconColor = Colors.white,
      iconSize = 18,
      shadow = green;

  const _RoundButton.soft({required this.icon, required this.iconColor, required this.iconSize, required this.onTap})
    : filled = false,
      fill = const Color(0xFFEDEDEA),
      shadow = Colors.black;

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color fill;
  final Color iconColor;
  final double iconSize;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44.r,
        height: 44.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadow.withValues(alpha: filled ? 0.30 : 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize.sp, color: iconColor),
      ),
    );
  }
}
