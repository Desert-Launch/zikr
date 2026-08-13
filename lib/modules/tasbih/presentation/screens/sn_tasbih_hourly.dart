import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/services/notifications/notification_window.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_note.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_switch.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

/// Tasbih preferences: the hourly notification (on/off here; its hours come
/// from the shared reminder window, edited in the salawat reminder sheet) and
/// the counter's haptics.
///
/// Laid out with the shared settings primitives so it reads as one surface
/// with [SNSettings], which links here rather than repeating the toggles.
class SNTasbihHourly extends StatelessWidget {
  const SNTasbihHourly({super.key});

  static const _canvas = Color(0xFFFAF9F7);

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBTasbih>();
    final isTab = context.isTablet;
    final window = Modular.get<BoxAppSettings>().reminderWindow();
    return BlocProvider.value(
      value: cb,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: Directionality(
          // Explicit extension — `localize_and_translate` also defines `isRTL`
          // on BuildContext, and importing the app extension makes it ambiguous.
          textDirection: ContextExtensions(context).isRTL
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WGradientAppBar(
                  title: 'tasbih_hourly_title'.tr(),
                  subtitle: 'tasbih_hourly_subtitle'.tr(),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  19.w,
                  isTab ? 14 : 18.h,
                  19.w,
                  isTab ? 20 : 24.h,
                ),
                sliver: SliverList.list(
                  children: [
                    WSettingsSectionLabel('tasbih_hourly_section'.tr()),
                    BlocSelector<CBTasbih, STasbih, bool>(
                      selector: (s) => s.hourlyEnabled,
                      builder: (context, enabled) => WSettingsGroup(
                        children: [
                          WSettingsRow(
                            icon: Icons.notifications_active_outlined,
                            title: 'tasbih_hourly_enable'.tr(),
                            // Reads the live window rather than naming 08–22:
                            // the hourly zekr shares the salawat reminder's
                            // window, and this screen doesn't own the pickers.
                            subtitle: _hourlyHint(context, window),
                            trailing: WSettingsSwitch(
                              value: enabled,
                              onChanged: (value) => _setHourly(cb, value),
                            ),
                            onTap: () => _setHourly(cb, !enabled),
                          ),
                        ],
                      ),
                    ),
                    WSettingsNote('tasbih_hourly_explainer'.tr()),
                    SizedBox(height: isTab ? 12 : 15.h),
                    WSettingsSectionLabel('tasbih_counter_section'.tr()),
                    BlocSelector<CBTasbih, STasbih, bool>(
                      selector: (s) => s.vibrate,
                      builder: (context, vibrate) => WSettingsGroup(
                        children: [
                          WSettingsRow(
                            icon: Icons.vibration_rounded,
                            title: 'tasbih_vibrate'.tr(),
                            subtitle: 'tasbih_vibrate_hint'.tr(),
                            trailing: WSettingsSwitch(
                              value: vibrate,
                              onChanged: cb.setVibrate,
                            ),
                            onTap: () => cb.setVibrate(!vibrate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the window bounds through [TimeOfDay.format] so they follow the
  /// device's 12/24-hour preference and locale, rather than a hard-coded string.
  String _hourlyHint(BuildContext context, NotificationWindow window) {
    return 'tasbih_hourly_hint'
        .tr()
        .replaceFirst(
          '{{start}}',
          TimeOfDay(hour: window.startHour, minute: 0).format(context),
        )
        .replaceFirst(
          '{{end}}',
          TimeOfDay(hour: window.endHour, minute: 0).format(context),
        );
  }

  /// Turning the reminder on needs the notification grant first — a silent
  /// channel still counts as a notification, so a denied prompt leaves the
  /// switch off rather than persisting a setting that can never fire.
  Future<void> _setHourly(CBTasbih cb, bool value) async {
    if (value) {
      final granted = await Modular.get<NotificationsService>()
          .requestPermission();
      if (!granted) return;
    }
    await cb.setHourlyEnabled(value);
  }
}
