import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_lock_screen.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_lock_screen.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_switch.dart';

/// Settings row for prayer times on the lock screen. On Android it switches
/// the pinned notification; on iOS, where only the user can add a Lock Screen
/// widget, a tap explains how. The caller leaves it out where
/// [SPrayerLockScreen.available] is false.
class WSettingsLockScreenRow extends StatelessWidget {
  const WSettingsLockScreenRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBPrayerLockScreen>();
    if (cubit.state.mode == ELockScreenMode.widget) {
      return WSettingsRow(
        icon: Icons.lock_clock_outlined,
        title: 'widget_lock_title'.tr(),
        subtitle: 'widget_lock_ios_hint'.tr(),
        onTap: () => AppAlert.notification(
          title: 'widget_lock_title'.tr(),
          body: 'widget_lock_ios_howto'.tr(),
        ),
      );
    }
    return BlocBuilder<CBPrayerLockScreen, SPrayerLockScreen>(
      bloc: cubit,
      builder: (context, state) {
        void toggle(bool value) => _toggle(cubit, value);
        return WSettingsRow(
          icon: Icons.lock_clock_outlined,
          title: 'widget_lock_title'.tr(),
          subtitle: 'widget_lock_hint'.tr(),
          trailing: WSettingsSwitch(
            value: state.enabled,
            onChanged: state.busy ? null : toggle,
          ),
          onTap: state.busy ? null : () => toggle(!state.enabled),
        );
      },
    );
  }

  Future<void> _toggle(CBPrayerLockScreen cubit, bool value) async {
    final applied = await cubit.setEnabled(value);
    if (value && !applied) AppAlert.error('widget_lock_denied'.tr());
  }
}
