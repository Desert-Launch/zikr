import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_icon.dart';

class WPrayerTile extends StatelessWidget {
  const WPrayerTile({
    super.key,
    required this.slot,
    required this.isNext,
    required this.notificationEnabled,
    this.windowStart,
    required this.green,
    required this.gold,
    required this.onNotificationChanged,
  });

  final PrayerSlot slot;
  final bool isNext;

  /// Time the progress bar starts filling from — the previous salah. Null when
  /// there are no timings to derive it from, which hides the bar's progress
  /// rather than guessing. Only read when [isNext].
  final DateTime? windowStart;

  final bool notificationEnabled;
  final Color green;
  final Color gold;
  final ValueChanged<bool>? onNotificationChanged;

  /// True once the prayer's time has elapsed and it is not the next prayer.
  bool get _isPast => !isNext && slot.time.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isNext ? null : Colors.white,
        gradient: isNext
            ? LinearGradient(
                colors: [Color(0xFF0D7E5E), Color(0xFF0A6349)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isNext ? gold : const Color(0xFFF0F0EE),
          width: isNext ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isNext ? _nextContent(context) : _normalContent(context),
    );
    return _isPast ? Opacity(opacity: 0.5, child: tile) : tile;
  }

  /// Leading edge → prayer icon + name; trailing edge → time and the alert
  /// toggle. Ordered leading-first so it mirrors correctly in both directions.
  Widget _normalContent(BuildContext context) {
    return Row(
      children: [
        WPrayerIcon(prayer: slot.prayer, active: false, green: green),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label(slot.prayer), style: AppTextStyles.ink14W500),
            if (!_isPast) ...[
              SizedBox(height: 3.h),
              Text('prayer_upcoming'.tr(), style: AppTextStyles.grey12W400),
            ],
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatTime(slot.time), style: AppTextStyles.ink18W500),
            if (onNotificationChanged != null)
              Row(
                children: [
                  Text(
                    notificationEnabled
                        ? 'prayer_notification_on'.tr()
                        : 'prayer_notification_off'.tr(),
                    style: AppTextStyles.grey12W400,
                  ),
                  SizedBox(width: 2.w),
                  Switch.adaptive(
                    value: notificationEnabled,
                    activeTrackColor: green,
                    onChanged: onNotificationChanged,
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    Icons.notifications_none_rounded,
                    color: green,
                    size: 20.r,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _nextContent(BuildContext context) {
    final remaining = slot.time.difference(DateTime.now());
    final progress = _progressToPrayer(slot.time);
    return Column(
      children: [
        Row(
          children: [
            WPrayerIcon(prayer: slot.prayer, active: true, green: green),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(slot.prayer), style: AppTextStyles.white14W500),
                Text(
                  '${'prayer_after'.tr()} ${_formatDuration(remaining)}',
                  style: AppTextStyles.white12W400,
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(slot.time), style: AppTextStyles.white18W500),
                Row(
                  children: [
                    Text(
                      notificationEnabled
                          ? 'prayer_notification_on'.tr()
                          : 'prayer_notification_off'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 8.sp,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // Gold track, white thumb.
                    //
                    // The track used to be white, and the thumb is white on
                    // both platforms when a switch is on — so "on" rendered as
                    // a blank white pill with nothing in it, on the one tile
                    // where the switch matters most. Gold is the same accent
                    // this tile already borders itself with, and it carries a
                    // white thumb clearly against the green.
                    //
                    // The thumb is pinned rather than left to the theme:
                    // Material's unselected thumb is `outline` grey, which is
                    // muddy on the gradient, and Cupertino's is always white.
                    // Pinning makes both platforms agree in both states.
                    Switch.adaptive(
                      value: notificationEnabled,
                      activeTrackColor: gold,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      onChanged: onNotificationChanged,
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20.r,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Divider(color: Colors.white.withValues(alpha: 0.24), height: 24.h),
        Row(
          children: [
            Text(
              'prayer_time_remaining'.tr(),
              style: AppTextStyles.white12W400.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: AppTextStyles.white12W400,
            ),
          ],
        ),

        SizedBox(height: 5.h),
        Directionality(
          textDirection: context.isRTL ? TextDirection.rtl : TextDirection.ltr,

          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.r),
            child: LinearProgressIndicator(
              minHeight: 7.h,
              value: progress,
              borderRadius: BorderRadius.circular(30.r),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Fraction of the gap between the previous salah and [target] that has
  /// elapsed.
  ///
  /// This used to measure from midnight, which said nothing about the wait it
  /// was drawing: the bar jumped to nearly full the moment isha ended, because
  /// most of the calendar day was spent even though none of the wait for fajr
  /// was — and once the list rolls into the next day, midnight isn't even on
  /// the same side of the target.
  double _progressToPrayer(DateTime target) {
    final start = windowStart;
    if (start == null || !start.isBefore(target)) return 0;
    final total = target.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  String _label(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => 'prayer_fajr'.tr(),
    EPrayer.sunrise => 'prayer_sunrise'.tr(),
    EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
    EPrayer.asr => 'prayer_asr'.tr(),
    EPrayer.maghrib => 'prayer_maghrib'.tr(),
    EPrayer.isha => 'prayer_isha'.tr(),
  };

  String _formatTime(DateTime time) => TimeFormat.hm12(time);
}
