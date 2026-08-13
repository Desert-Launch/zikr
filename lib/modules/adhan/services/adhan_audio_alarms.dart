import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Which OS settings page [AdhanAudioAlarms.openOsSettings] should deep-link
/// to. Each maps to a native intent (Android) or `UIApplication.openSettings`
/// (iOS) — the escape hatches for the two things that silently break a
/// background adhan in the real world.
enum AdhanOsSetting {
  /// Android: "Alarms & reminders" (SCHEDULE_EXACT_ALARM). iOS: no-op.
  exactAlarm,

  /// Android: battery-optimization exemption. iOS: no-op.
  batteryOptimization,

  /// Android 14+: "Special app access → Full screen notifications", the only
  /// page carrying the USE_FULL_SCREEN_INTENT toggle. Falls back to the app's
  /// notification settings on older versions. iOS: the app's Settings page.
  fullScreenIntent,

  /// Android: "Display over other apps" for this package — what lets the adhan
  /// screen appear over a foreground app rather than only on the lockscreen.
  /// iOS: no-op.
  overlay,

  /// Android: the app's notification settings. iOS: the app's Settings page.
  notifications,

  /// Android: the OEM autostart / protected-app manager, where one exists
  /// (Xiaomi, Oppo, Vivo, Realme, Huawei…). iOS: no-op.
  oemAutostart,
}

/// Granular permission snapshot for the alarm path. Everything is `true` on
/// platforms/versions where the permission doesn't exist, so callers can treat
/// `false` as "genuinely missing and worth prompting for".
class AdhanAlarmPermissions extends Equatable {
  const AdhanAlarmPermissions({
    this.canScheduleExact = true,
    this.canUseFullScreenIntent = true,
    this.canDrawOverlays = true,
    this.isBatteryOptimized = false,
    this.hasOemAutostartManager = false,
  });

  /// Android 12+ SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM grant.
  final bool canScheduleExact;

  /// Android 14+ USE_FULL_SCREEN_INTENT grant — without it the lockscreen
  /// activity is demoted to a heads-up notification.
  final bool canUseFullScreenIntent;

  /// Android 6+ "Display over other apps". Without it the adhan screen can
  /// only appear on the lockscreen / with the screen off — never over an app
  /// the user is currently using.
  final bool canDrawOverlays;

  /// True when the app is still subject to battery optimization, which lets
  /// the OS delay or drop the alarm.
  final bool isBatteryOptimized;

  /// True on OEMs that ship an extra autostart/protected-app whitelist
  /// ([AdhanOsSetting.oemAutostart] can open it).
  final bool hasOemAutostartManager;

  /// True when nothing stands between a scheduled alarm and the user.
  bool get allGranted =>
      canScheduleExact &&
      canUseFullScreenIntent &&
      canDrawOverlays &&
      !isBatteryOptimized &&
      !hasOemAutostartManager;

  @override
  List<Object?> get props => [
    canScheduleExact,
    canUseFullScreenIntent,
    canDrawOverlays,
    isBatteryOptimized,
    hasOemAutostartManager,
  ];
}

/// Bridge to the native exact-alarm + foreground-service + full-screen-activity
/// stack that plays the FULL adhan and raises an over-the-lockscreen alarm at
/// prayer time — even when the app is killed. The notification path can only
/// play a short channel sound, so this is the only way to auto-play a
/// multi-minute adhan in the background.
///
/// Android runs the real thing (AlarmManager.setAlarmClock → BroadcastReceiver
/// → mediaPlayback foreground service → full-screen Activity). On iOS the same
/// channel reaches AlarmKit (26+) or a critical alert (older), which is the
/// ceiling Apple allows — see `ios/Runner/Adhan/`.
///
/// Every method is a safe no-op when the native channel isn't reachable —
/// notably a background isolate (the weekly refresh), where the
/// MainActivity-registered channel doesn't exist, so a [MissingPluginException]
/// is swallowed and the caller keeps the notification-sound fallback.
class AdhanAudioAlarms {
  static const MethodChannel _channel = MethodChannel(
    'com.zikr.mapp/adhan_alarm',
  );

  /// Arms an alarm at [when] that plays the `res/raw/<rawRes>` clip
  /// (Android) or the bundled `<rawRes>.caf` (iOS).
  ///
  /// [title]/[body]/[stopLabel]/[openLabel] are the localized texts for the
  /// playback notification, the full-screen alarm UI, and its two actions.
  /// [prayerKey] identifies the prayer for the full-screen UI and for the
  /// deep-link back into the app. [fullScreen] raises the over-the-lockscreen
  /// alarm; when false the alarm still plays audio but stays a notification.
  ///
  /// [volume] (0–100) is baked into the alarm rather than read when it fires:
  /// the alarm wakes a broadcast receiver with no Flutter engine attached, so
  /// there is no isolate left to ask — the same reason [rawRes] travels this
  /// way. Android raises the device's ALARM stream to that share for the length
  /// of the adhan and restores it afterwards; iOS ignores it (Apple caps the
  /// notification path at system volume).
  ///
  /// Returns true when the alarm was actually armed natively. A false result
  /// (unreachable channel, missing authorization, unsupported OS) is the
  /// caller's signal to keep its own notification as the audible fallback —
  /// never treat it as fatal.
  Future<bool> schedule({
    required int id,
    required DateTime when,
    required String rawRes,
    required String title,
    required String body,
    required String stopLabel,
    required String openLabel,
    required String prayerKey,
    bool fullScreen = true,
    int volume = 100,
  }) async {
    try {
      final armed = await _channel.invokeMethod<bool>('schedule', {
        'id': id,
        'triggerAtMillis': when.millisecondsSinceEpoch,
        'rawRes': rawRes,
        'title': title,
        'body': body,
        'stopLabel': stopLabel,
        'openLabel': openLabel,
        'prayerKey': prayerKey,
        'fullScreen': fullScreen,
        'volume': volume.clamp(0, 100),
      });
      return armed ?? false;
    } on MissingPluginException {
      // Background isolate — no native channel. Caller falls back to the
      // notification sound for this window.
      return false;
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm schedule failed (id=$id): $e',
        tag: 'AdhanAudioAlarms',
      );
      return false;
    }
  }

  /// Cancels a single armed alarm — used when one prayer is toggled off
  /// without rebuilding the whole window.
  Future<void> cancel(int id) async {
    try {
      await _channel.invokeMethod('cancel', {'id': id});
    } on MissingPluginException {
      // ignore — see [schedule].
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm cancel failed (id=$id): $e',
        tag: 'AdhanAudioAlarms',
      );
    }
  }

  /// Cancels every armed adhan alarm apart from [except]. Called before
  /// re-arming a fresh window, and whenever full-adhan background mode is
  /// turned off.
  ///
  /// [except] is for alarms that don't belong to the rolling window and so are
  /// never re-armed by the rebuild that follows — currently just the one-shot
  /// test alarm. Without it, arming a test and then triggering any window
  /// rebuild (opening the prayer screen is enough) silently cancels the test
  /// before it fires, leaving only its deliberately-silent companion
  /// notification and no full-screen alarm at all.
  Future<void> cancelAll({Set<int> except = const {}}) async {
    try {
      await _channel.invokeMethod('cancelAll', {'exceptIds': except.toList()});
    } on MissingPluginException {
      // ignore — see [schedule].
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm cancelAll failed: $e',
        tag: 'AdhanAudioAlarms',
      );
    }
  }

  /// Reads the current permission snapshot. Returns the all-granted default
  /// when the channel is unreachable, so a background isolate never shows
  /// spurious warnings.
  Future<AdhanAlarmPermissions> permissions() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'permissions',
      );
      if (raw == null) return const AdhanAlarmPermissions();
      return AdhanAlarmPermissions(
        canScheduleExact: raw['canScheduleExact'] as bool? ?? true,
        canUseFullScreenIntent: raw['canUseFullScreenIntent'] as bool? ?? true,
        canDrawOverlays: raw['canDrawOverlays'] as bool? ?? true,
        isBatteryOptimized: raw['isBatteryOptimized'] as bool? ?? false,
        hasOemAutostartManager: raw['hasOemAutostartManager'] as bool? ?? false,
      );
    } on MissingPluginException {
      return const AdhanAlarmPermissions();
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm permission read failed: $e',
        tag: 'AdhanAudioAlarms',
      );
      return const AdhanAlarmPermissions();
    }
  }

  /// Requests the platform's alarm authorization.
  ///
  /// iOS 26+: the AlarmKit authorization prompt. iOS < 26: the critical-alert
  /// prompt (only shown when the entitlement is provisioned — see
  /// `docs/ios_critical_alerts_justification.md`). Android has no runtime
  /// prompt for exact alarms; use [openOsSettings] instead. Returns false when
  /// authorization was denied or the channel is unreachable.
  Future<bool> requestAuthorization() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestAuthorization');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm authorization request failed: $e',
        tag: 'AdhanAudioAlarms',
      );
      return false;
    }
  }

  /// Deep-links to the OS settings page for [which]. Returns false when the
  /// page couldn't be opened (no such page on this OEM/version) so the caller
  /// can fall back to showing manual instructions.
  Future<bool> openOsSettings(AdhanOsSetting which) async {
    try {
      final opened = await _channel.invokeMethod<bool>('openOsSettings', {
        'which': which.name,
      });
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      AppLogger.warning(
        'Adhan alarm openOsSettings(${which.name}) failed: $e',
        tag: 'AdhanAudioAlarms',
      );
      return false;
    }
  }

  /// Manufacturer name (lowercase) on Android, empty elsewhere. Drives the
  /// OEM-specific autostart guidance copy.
  Future<String> deviceManufacturer() async {
    if (!Platform.isAndroid) return '';
    try {
      final name = await _channel.invokeMethod<String>('manufacturer');
      return name?.toLowerCase() ?? '';
    } on MissingPluginException {
      return '';
    } catch (e) {
      return '';
    }
  }
}
