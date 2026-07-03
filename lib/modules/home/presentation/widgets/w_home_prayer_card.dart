import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/time_format.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_prayer_chip.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

/// Per-prayer accent colour + emoji for the chip row.
({Color color, String emoji}) _prayerStyle(EPrayer prayer) => switch (prayer) {
  EPrayer.fajr => (color: const Color(0xFFE2705B), emoji: '🌅'),
  EPrayer.sunrise => (color: const Color(0xFFF2A33C), emoji: '☀️'),
  EPrayer.dhuhr => (color: const Color(0xFFF2C037), emoji: '🌤️'),
  EPrayer.asr => (color: const Color(0xFF3FA9C4), emoji: '🌥️'),
  EPrayer.maghrib => (color: const Color(0xFFE8743B), emoji: '🌇'),
  EPrayer.isha => (color: const Color(0xFF6C63B5), emoji: '🌙'),
};

String _prayerLabel(EPrayer prayer) => switch (prayer) {
  EPrayer.fajr => 'prayer_fajr'.tr(),
  EPrayer.sunrise => 'prayer_sunrise'.tr(),
  EPrayer.dhuhr => 'prayer_dhuhr'.tr(),
  EPrayer.asr => 'prayer_asr'.tr(),
  EPrayer.maghrib => 'prayer_maghrib'.tr(),
  EPrayer.isha => 'prayer_isha'.tr(),
};

/// Home prayer card: next prayer, countdown, progress bar, and the chip row.
class WHomePrayerCard extends StatelessWidget {
  const WHomePrayerCard({super.key, required this.state, required this.green});

  final SPrayerTimes state;
  final Color green;

  static const _gold = Color(0xFFD6A72C);

  @override
  Widget build(BuildContext context) {
    final next = state.nextPrayer;
    final allSlots = state.slots.isNotEmpty
        ? state.slots
        : [
            EPrayer.fajr,
            EPrayer.sunrise,
            EPrayer.dhuhr,
            EPrayer.asr,
            EPrayer.maghrib,
            EPrayer.isha,
          ].map((p) => PrayerSlot(prayer: p, time: DateTime.now())).toList();
    // Show the five prayers that are not the highlighted "next" one.
    // final excluded = next?.prayer ?? EPrayer.isha;
    final slots = allSlots.toList();

    final caption = StringBuffer('prayer_next_label'.tr());
    if (state.cityName.isNotEmpty) {
      caption
        ..write(' ')
        ..write('home_timing'.tr().replaceFirst('{{city}}', state.cityName));
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Modular.to.pushNamed(RoutesNames.prayerBase),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: green,
                  child: Icon(Icons.access_time_rounded, color: Colors.white, size: 24.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        next == null
                            ? 'prayer_title'.tr()
                            : 'home_next_prayer'.tr().replaceFirst('{{name}}', _prayerLabel(next.prayer)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xFF252525), fontSize: 20.sp, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      next == null ? TimeFormat.h12Plain(DateTime.now()) : TimeFormat.h12Plain(next.time),
                      style: TextStyle(color: green, fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.0),
                    ),
                    if (_remaining(next).isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(color: green, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _remaining(next),
                            style: TextStyle(color: Colors.grey[600], fontSize: 8.sp),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _buildProgressBar(),
            SizedBox(height: 18.h),
            Container(height: 1, color: const Color(0xFFEDEAE3)),
            SizedBox(height: 16.h),
            Row(
              children: slots
                  .map(
                    (slot) => Expanded(
                      child: WHomePrayerChip(
                        label: _prayerLabel(slot.prayer),
                        time: state.slots.isEmpty ? '--:--' : TimeFormat.h12Plain(slot.time),
                        style: _prayerStyle(slot.prayer),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _remaining(PrayerSlot? next) {
    if (next == null) return '';
    final diff = next.time.difference(DateTime.now());
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) {
      return 'home_remaining_m'.tr().replaceFirst('{{m}}', '$m');
    }
    return 'home_remaining_hm'.tr().replaceFirst('{{h}}', '$h').replaceFirst('{{m}}', '$m');
  }

  /// Fraction of the window between the previous salah and the next one that has
  /// already elapsed: (now − prevPrayer) / (nextPrayer − prevPrayer).
  Widget _buildProgressBar() {
    final p = _progress();
    final filled = (p * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 8.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: filled,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [green, _gold],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1000 - filled,
              child: const ColoredBox(color: Color(0xFFEDEAE3)),
            ),
          ],
        ),
      ),
    );
  }

  /// Fraction of the current prayer window that has elapsed:
  /// (now − previous salah) / (next salah − previous salah).
  /// Sunrise is skipped (not prayed) and the window wraps around midnight.
  double _progress() {
    final now = DateTime.now();
    final times = state.slots.where((s) => s.prayer != EPrayer.sunrise).map((s) => s.time).toList()..sort();
    if (times.length < 2) return 0;

    DateTime? prev;
    DateTime? next;
    for (final t in times) {
      if (t.isAfter(now)) {
        next = t;
        break;
      }
      prev = t;
    }
    // Before today's first salah → window opened with yesterday's last one.
    prev ??= times.last.subtract(const Duration(days: 1));
    // After today's last salah → window closes with tomorrow's first one.
    next ??= times.first.add(const Duration(days: 1));

    final total = next.difference(prev).inSeconds;
    if (total <= 0) return 0;
    final elapsed = now.difference(prev).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0).toDouble();
  }
}
