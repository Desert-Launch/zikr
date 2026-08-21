import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
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
    required this.cubit,
  });

  final String prayerKey;
  final String title;
  final SAdhanSettings state;
  final CBAdhanSettings cubit;

  /// Position in `notifyForPrayer`. Sunrise sits at the end rather than in
  /// clock order — see [MPrayerSettings.notifyForPrayer] for why.
  int get _notifyIndex => switch (prayerKey) {
    'fajr' => 0,
    'dhuhr' => 1,
    'asr' => 2,
    'maghrib' => 3,
    'isha' => 4,
    'sunrise' => MPrayerSettings.sunriseIndex,
    _ => -1,
  };

  /// Sunrise alerts, but it is not a salah: there is no adhan for it, so the
  /// row toggles a plain notification and never opens the voice picker.
  bool get isSunrise => prayerKey == 'sunrise';

  bool get enabled =>
      state.enabled &&
      _notifyIndex >= 0 &&
      _notifyIndex < state.notifyForPrayer.length &&
      state.notifyForPrayer[_notifyIndex];

  @override
  Widget build(BuildContext context) {
    final voice = state.voiceNamePerPrayer[prayerKey];
    // See WAdhanSettingRow — fixed logical sizes on tablet, where `.h`/`.w`
    // over-scale against the 780x844 design size.
    final isTab = context.isTablet;
    return InkWell(
      // Sunrise has no voice to pick, so pressing the row toggles the alert
      // rather than doing nothing at all. Every other prayer opens its picker;
      // its bell is the toggle.
      onTap: isSunrise
          ? () => cubit.togglePrayer(_notifyIndex, !enabled)
          : () async {
              await Modular.to.pushNamed(AdhanRoutes.voicePicker(prayerKey));
              await cubit.refreshVoice();
            },
      child: SizedBox(
        height: isTab ? 62 : 74.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTab ? 27.w : 15.w),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(22.r),
                onTap: () => cubit.togglePrayer(_notifyIndex, !enabled),
                child: WAdhanIconCircle(
                  icon: enabled ? Icons.notifications_none_rounded : Icons.notifications_off_outlined,
                  color: enabled ? const Color(0xFF2F7E63) : const Color(0xFF8B8B8B),
                ),
              ),
              SizedBox(width: isTab ? 18.w : 13.w),
              Text(title, style: AppTextStyles.ink16W400),
              const Spacer(),
              Text(
                isSunrise
                    ? (enabled ? 'adhan_sunrise_alert'.tr() : 'adhan_off'.tr())
                    : (voice?.isNotEmpty ?? false)
                    ? voice ?? ''
                    : 'adhan_voice_none'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.grey12W400,
              ),

              // No chevron on sunrise: the row opens nothing, and an affordance
              // that leads nowhere is what made this look broken in the first
              // place.
              if (!isSunrise) ...[
                SizedBox(width: 4.w),
                WLocalizeRotation(
                  child: Icon(Icons.chevron_left_rounded, color: const Color(0xFF777777), size: 21.r),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
