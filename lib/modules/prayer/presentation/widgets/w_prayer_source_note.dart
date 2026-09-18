import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

/// The quiet line under the header that marks times known to be behind — a
/// cached month that could not be refreshed, or an offline calculation —
/// instead of letting them pass as live.
///
/// It used to name the calculation authority too; that line is gone from the
/// list (the authority is still shown on the calculation settings screen), so
/// this renders nothing at all in the normal case.
class WPrayerSourceNote extends StatelessWidget {
  const WPrayerSourceNote({required this.state, super.key});

  static const _amber = Color(0xFFB07A18);

  final SPrayerTimes state;

  @override
  Widget build(BuildContext context) {
    final stale = _staleKey();
    if (stale == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 13.r, color: _amber),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              stale.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 9.5.sp, color: _amber),
            ),
          ),
        ],
      ),
    );
  }

  String? _staleKey() => switch (state.source) {
    EPrayerSource.staleCache => 'prayer_source_offline',
    EPrayerSource.calculated => 'prayer_source_calculated',
    _ => null,
  };
}
