import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

class WPrayerIcon extends StatelessWidget {
  const WPrayerIcon({super.key, required this.prayer, required this.active, required this.green});

  final EPrayer prayer;
  final bool active;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r,
      height: 52.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFF8F7F1),
        gradient: LinearGradient(
          colors: [const Color.fromARGB(255, 240, 240, 240), const Color.fromARGB(255, 255, 255, 255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 7, offset: Offset(0, 10))],
      ),
      child: Text(_emoji(prayer), style: TextStyle(fontSize: 20.sp)),
    );
  }

  String _emoji(EPrayer prayer) => switch (prayer) {
    EPrayer.fajr => '🌅',
    EPrayer.sunrise => '☀️',
    EPrayer.dhuhr => '🌤️',
    EPrayer.asr => '🌥️',
    EPrayer.maghrib => '🌇',
    EPrayer.isha => '🌙',
  };
}
