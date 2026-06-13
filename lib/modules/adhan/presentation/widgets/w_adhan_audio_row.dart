import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// A selectable adhan voice row with an inline play / stop preview button.
class WAdhanAudioRow extends StatelessWidget {
  const WAdhanAudioRow({
    super.key,
    required this.adhan,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPlay,
    required this.onStop,
  });

  final MAdhan adhan;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: SizedBox(
        height: 72.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              const WAdhanIconCircle(icon: Icons.notifications_none_rounded),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  adhan.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: selected ? const Color(0xFF42BE88) : const Color(0xFF303030),
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: const Color(0xFF42BE88), size: 22.r),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: playing ? onStop : onPlay,
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF2F7E63),
                  size: 27.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
