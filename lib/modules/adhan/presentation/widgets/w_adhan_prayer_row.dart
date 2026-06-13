import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/presentation/widgets/w_adhan_icon_circle.dart';

/// A single prayer row on the alerts screen: a toggle badge, the prayer name,
/// and the selected adhan voice. Tapping opens the voice picker.
class WAdhanPrayerRow extends StatelessWidget {
  const WAdhanPrayerRow({
    super.key,
    required this.prayerKey,
    required this.title,
    required this.state,
    required this.index,
    required this.cubit,
  });

  final String prayerKey;
  final String title;
  final SAdhanSettings state;
  final int index;
  final CBAdhanSettings cubit;

  bool get isSunrise => prayerKey == 'sunrise';
  bool get enabled =>
      !isSunrise &&
      state.enabled &&
      index < state.notifyForPrayer.length &&
      state.notifyForPrayer[index];

  @override
  Widget build(BuildContext context) {
    final voice = state.voiceNamePerPrayer[prayerKey];
    return InkWell(
      onTap: isSunrise
          ? null
          : () async {
              await Modular.to.pushNamed(AdhanRoutes.voicePicker(prayerKey));
              await cubit.refreshVoice();
            },
      child: SizedBox(
        height: 74.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(22.r),
                onTap: isSunrise ? null : () => cubit.togglePrayer(index, !enabled),
                child: WAdhanIconCircle(
                  icon: enabled
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_off_outlined,
                  color: enabled ? const Color(0xFF2F7E63) : const Color(0xFF8B8B8B),
                ),
              ),
              SizedBox(width: 13.w),
              Text(
                title,
                style: GoogleFonts.cairo(fontSize: 14.sp, color: const Color(0xFF303030)),
              ),
              const Spacer(),
              Text(
                isSunrise
                    ? 'adhan_off'.tr()
                    : (voice?.isNotEmpty ?? false)
                        ? voice ?? ''
                        : 'adhan_voice_none'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontSize: 9.sp, color: const Color(0xFF777777)),
              ),
              if (!isSunrise) ...[
                SizedBox(width: 4.w),
                Icon(Icons.chevron_left_rounded, color: const Color(0xFF777777), size: 21.r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
