import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_loading_overlay.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';

/// A single radio station row: leading flag/icon, name + meta, play/pause button.
class WRadioStationTile extends StatelessWidget {
  const WRadioStationTile({
    super.key,
    required this.station,
    required this.isActive,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);

  final MRadioStation station;
  final bool isActive;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = station.isNational ? _green : _gold;
    final meta = _meta(isArabic);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.5) : const Color(0x11000000),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                _Leading(station: station, accent: accent),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station.displayName(isArabic: isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ink16W700,
                      ),
                      if (meta != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.grey12W400,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _PlayButton(
                  accent: accent,
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _meta(bool isArabic) {
    final parts = <String>[
      if (station.country != null && station.country!.isNotEmpty) station.country!,
      if (station.frequency != null && station.frequency!.isNotEmpty)
        station.frequency!,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.station, required this.accent});

  final MRadioStation station;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: station.flag != null
          ? Text(station.flag!, style: TextStyle(fontSize: 24.sp))
          : Icon(Icons.radio_rounded, color: accent, size: 24.r),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.accent,
    required this.isPlaying,
    required this.isLoading,
  });

  final Color accent;
  final bool isPlaying;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      child: isLoading
          ? Stack(
              children: [
                WLoadingOverlay(
                  show: true,
                  inline: true,
                  transparent: true,
                  indicatorColor: Colors.white,
                ),
              ],
            )
          : Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24.r,
            ),
    );
  }
}
