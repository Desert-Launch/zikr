import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_audio_alarms.dart';

/// One OS grant the over-the-lockscreen adhan depends on, flattened into what a
/// settings row needs to draw it. Both grants live on a system settings page —
/// there is no runtime prompt for either — so the "switch" is really a
/// deep-link plus a live reflection of what the OS currently reports.
class AlarmPermissionInfo {
  const AlarmPermissionInfo({
    required this.setting,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.granted,
  });

  final AdhanOsSetting setting;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final bool granted;
}

/// The grants that decide whether the adhan can take over the screen, in the
/// order they matter: without the overlay permission it can never appear over a
/// foreground app, and without the full-screen-intent grant (Android 14+) it
/// can't even take the lockscreen.
///
/// Empty on iOS, where neither concept exists — callers can render the result
/// unconditionally and get nothing on the platforms it doesn't apply to.
List<AlarmPermissionInfo> alarmPermissionInfos(AdhanAlarmPermissions perms) {
  if (!Platform.isAndroid) return const [];
  return [
    AlarmPermissionInfo(
      setting: AdhanOsSetting.overlay,
      icon: Icons.layers_rounded,
      titleKey: 'alarm_perm_overlay_title',
      subtitleKey: 'alarm_perm_overlay_body',
      granted: perms.canDrawOverlays,
    ),
    AlarmPermissionInfo(
      setting: AdhanOsSetting.fullScreenIntent,
      icon: Icons.fullscreen_rounded,
      titleKey: 'alarm_perm_fullscreen_title',
      subtitleKey: 'alarm_perm_fullscreen_body',
      granted: perms.canUseFullScreenIntent,
    ),
  ];
}

/// Trailing switch for an [AlarmPermissionInfo].
///
/// Neither direction can be applied in-process — Android only lets the user
/// grant OR revoke these from the settings page — so both flips deep-link
/// there and the real value lands on the next permission refresh.
class WAlarmPermissionSwitch extends StatelessWidget {
  const WAlarmPermissionSwitch({
    super.key,
    required this.granted,
    required this.onTap,
  });

  static const _green = Color(0xFF2F7E63);

  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: .75,
      child: Switch(
        value: granted,
        activeTrackColor: _green,
        thumbColor: WidgetStateProperty.all(
          granted ? Colors.white : Colors.grey.shade400,
        ),
        onChanged: (_) => onTap(),
      ),
    );
  }
}

/// Provides [CBAdhanSettings] to [child] and re-reads the OS grants whenever
/// the app comes back to the foreground.
///
/// Both permissions are changed on a settings page the user leaves the app for,
/// and Android gives no callback when they do — without this the switches would
/// keep showing the pre-departure value until something else reloaded the
/// cubit. Wrap any screen that renders [alarmPermissionInfos].
class WAlarmPermissionRefresher extends StatefulWidget {
  const WAlarmPermissionRefresher({super.key, required this.child});

  final Widget child;

  @override
  State<WAlarmPermissionRefresher> createState() =>
      _WAlarmPermissionRefresherState();
}

class _WAlarmPermissionRefresherState extends State<WAlarmPermissionRefresher>
    with WidgetsBindingObserver {
  // App-wide singleton (registered in AppModule), so this is the same instance
  // the adhan settings screen drives — no second source of truth.
  final CBAdhanSettings _cubit = Modular.get<CBAdhanSettings>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.refreshAlarmPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cubit.refreshAlarmPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _cubit, child: widget.child);
  }
}
