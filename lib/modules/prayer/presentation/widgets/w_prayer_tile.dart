import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/widgets/w_prayer_icon.dart';

class WPrayerTile extends StatelessWidget {
  const WPrayerTile({
    super.key,
    required this.slot,
    required this.isNext,
    required this.isCurrent,
    required this.notificationEnabled,
    required this.green,
    required this.gold,
    required this.onNotificationChanged,
  });

  final PrayerSlot slot;
  final bool isNext;
  final bool isCurrent;
  final bool notificationEnabled;
  final Color green;
  final Color gold;
  final ValueChanged<bool>? onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: isNext ? 13.h : 10.h),
      decoration: BoxDecoration(
        color: isNext ? green : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isNext ? gold : const Color(0xFFF0F0EE), width: isNext ? 1.5 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: isNext ? _nextContent(context) : _normalContent(context),
    );
  }

  Widget _normalContent(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTime(slot.time),
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[700]),
            ),
            if (onNotificationChanged != null)
              Row(
                children: [
                  Icon(Icons.notifications_none_rounded, color: green, size: 14.r),
                  SizedBox(width: 3.w),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch.adaptive(
                      value: notificationEnabled,
                      activeTrackColor: green,
                      onChanged: onNotificationChanged,
                    ),
                  ),
                  Text(
                    notificationEnabled ? 'prayer_notification_on'.tr() : 'prayer_notification_off'.tr(),
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _label(slot.prayer),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              isCurrent ? 'prayer_current_window'.tr() : 'prayer_upcoming'.tr(),
              style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
            ),
          ],
        ),
        SizedBox(width: 10.w),
        WPrayerIcon(prayer: slot.prayer, active: false, green: green),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(slot.time),
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: Colors.white, size: 14.r),
                    SizedBox(width: 3.w),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch.adaptive(
                        value: notificationEnabled,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        onChanged: onNotificationChanged,
                      ),
                    ),
                    Text(
                      notificationEnabled ? 'prayer_notification_on'.tr() : 'prayer_notification_off'.tr(),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 8.sp),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _label(slot.prayer),
                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${'prayer_after'.tr()} ${_formatDuration(remaining)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 9.sp),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            WPrayerIcon(prayer: slot.prayer, active: true, green: green),
          ],
        ),
        Divider(color: Colors.white.withValues(alpha: 0.14), height: 14.h),
        Row(
          children: [
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(color: Colors.white, fontSize: 8.sp),
            ),
            const Spacer(),
            Text(
              'prayer_time_remaining'.tr(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 8.sp),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            minHeight: 4.h,
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
    );
  }

  double _progressToPrayer(DateTime target) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final total = target.difference(start).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(start).inSeconds / total).clamp(0, 1).toDouble();
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
