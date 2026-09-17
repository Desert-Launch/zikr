import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_times.dart';

/// The quiet line under the header that says where these times came from.
///
/// Two jobs, both about not misleading the reader:
///
///  * it names the authority the times were calculated with, so "my app and my
///    mosque disagree" has an answer on the screen rather than in a support
///    thread;
///  * it marks times that are known to be behind — a cached month that could
///    not be refreshed, or an offline calculation — instead of letting them
///    pass as live.
///
/// It renders nothing when there is nothing to say, which is the normal case.
class WPrayerSourceNote extends StatelessWidget {
  const WPrayerSourceNote({required this.state, super.key});

  static const _amber = Color(0xFFB07A18);
  static const _muted = Color(0xFF8A938F);

  final SPrayerTimes state;

  @override
  Widget build(BuildContext context) {
    final stale = _staleKey();
    final method = state.methodName;
    if (stale == null && method.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (stale != null)
            Row(
              mainAxisSize: MainAxisSize.min,
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
          if (method.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: stale == null ? 0 : 4.h),
              child: Text(
                'prayer_method_label'.tr().replaceFirst('{{method}}', method),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontSize: 9.5.sp, color: _muted),
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
