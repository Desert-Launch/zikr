import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/notifications/hourly_rotation.dart';
import 'package:quran/core/services/notifications/notification_window.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_group.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_note.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_section_label.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';

/// The hourly zekr's own range: start/end pickers, plus a note that says when
/// the range is too short for every zekr and they spread over several days.
///
/// Picking either end re-arms the feed straight away (see
/// [CBTasbih.setHourlyWindow]). Only the hour is kept — the feed fires once per
/// hour and picks its own minute to dodge the prayer times, so offering minutes
/// would promise a precision it doesn't honour.
class WHourlyRangeSection extends StatelessWidget {
  const WHourlyRangeSection({required this.cubit, super.key});

  final CBTasbih cubit;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBTasbih, STasbih, (bool, int, int, int)>(
      bloc: cubit,
      selector: (s) => (
        s.hourlyEnabled,
        s.hourlyStartHour,
        s.hourlyEndHour,
        s.hourlyZikrCount,
      ),
      builder: (context, values) {
        final (enabled, startHour, endHour, zikrCount) = values;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WSettingsSectionLabel('tasbih_hourly_range_section'.tr()),
            WSettingsGroup(
              children: [
                WSettingsRow(
                  icon: Icons.wb_twilight_rounded,
                  title: 'tasbih_hourly_range_start'.tr(),
                  value: TimeOfDay(hour: startHour, minute: 0).format(context),
                  onTap: enabled
                      ? () => _pick(context, startHour, endHour, start: true)
                      : null,
                ),
                WSettingsRow(
                  icon: Icons.bedtime_outlined,
                  title: 'tasbih_hourly_range_end'.tr(),
                  value: TimeOfDay(hour: endHour, minute: 0).format(context),
                  onTap: enabled
                      ? () => _pick(context, startHour, endHour, start: false)
                      : null,
                ),
              ],
            ),
            WSettingsNote(_note(startHour, endHour, zikrCount)),
          ],
        );
      },
    );
  }

  /// The rotation explainer when the range can't hold every zekr in a day,
  /// otherwise the plain description of the range.
  String _note(int startHour, int endHour, int zikrCount) {
    final hours = NotificationWindow(
      startHour: startHour,
      endHour: endHour,
    ).hours.length;
    final rotation = HourlyRotation(slotsPerDay: hours, zikrCount: zikrCount);
    if (zikrCount == 0 || rotation.fitsInOneDay) {
      return 'tasbih_hourly_range_hint'.tr();
    }
    return 'tasbih_hourly_rotation_hint'
        .tr()
        .replaceFirst('{{count}}', '$zikrCount')
        .replaceFirst('{{days}}', '${rotation.daysToCoverAll}');
  }

  Future<void> _pick(
    BuildContext context,
    int startHour,
    int endHour, {
    required bool start,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ? startHour : endHour, minute: 0),
    );
    if (picked == null) return;
    await cubit.setHourlyWindow(
      start ? picked.hour : startHour,
      start ? endHour : picked.hour,
    );
  }
}
