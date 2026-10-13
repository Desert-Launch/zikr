import 'dart:io';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Bridge to the lock-screen prayer notification — Android's
/// `PrayerLockNotification`, an ongoing notification that mirrors the home
/// widget. Android gives apps no way to put a widget on the lock screen, so
/// this is how the next prayer stays there.
///
/// The switch is stored natively, not in Hive: the widget provider decides
/// whether to post at boot and from its alarms, with no Flutter engine around.
/// So this holds no state of its own — every read asks the platform.
///
/// The channel is Android only: elsewhere [canPin] is false and every call
/// is a no-op. An unreachable channel (a background isolate) is logged and
/// swallowed. iOS has no equivalent an app can switch on — its lock-screen
/// form is a widget the user adds ([hasLockScreenWidget]).
class DSPrayerLockScreen {
  static const MethodChannel _channel = MethodChannel(
    'com.zikr.mapp/prayer_lock_screen',
  );

  static const String _tag = 'DSPrayerLockScreen';

  /// Whether the app itself can put prayer times on the lock screen.
  bool get canPin => Platform.isAndroid;

  /// iOS 16+, where the prayer widget has Lock Screen faces
  /// (`ios/PrayerWidget/PrayerLockScreenView.swift`).
  bool get hasLockScreenWidget =>
      Platform.isIOS && (_iosMajorVersion() ?? 16) >= 16;

  /// From e.g. `Version 17.2 (Build 21C62)`; null if the format ever changes,
  /// which the caller treats as a current iOS.
  static int? _iosMajorVersion() {
    final match = RegExp(
      r'(\d+)\.',
    ).firstMatch(Platform.operatingSystemVersion);
    return int.tryParse(match?.group(1) ?? '');
  }

  Future<bool> isEnabled() async {
    if (!canPin) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (e) {
      AppLogger.warning('Lock-screen state read failed: $e', tag: _tag);
      return false;
    }
  }

  /// Stores the switch and posts or removes the notification right away.
  ///
  /// False when switching on was refused because the notification could not
  /// be seen — notifications are blocked for the app or for its channel — or
  /// when the platform could not be reached.
  Future<bool> setEnabled(bool enabled) async {
    if (!canPin) return false;
    try {
      return await _channel.invokeMethod<bool>('setEnabled', {
            'enabled': enabled,
          }) ??
          false;
    } catch (e) {
      AppLogger.warning('Lock-screen switch failed: $e', tag: _tag);
      return false;
    }
  }

  /// Re-posts the notification from the stored snapshot.
  ///
  /// For app launch: a force-stop takes the notification down, and a launch
  /// that resolves an unchanged schedule publishes nothing that would bring
  /// it back.
  Future<void> refresh() async {
    if (!canPin) return;
    try {
      await _channel.invokeMethod<void>('refresh');
    } catch (e) {
      AppLogger.warning('Lock-screen refresh failed: $e', tag: _tag);
    }
  }
}
