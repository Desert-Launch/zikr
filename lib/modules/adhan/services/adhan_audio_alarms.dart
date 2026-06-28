import 'dart:io';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Bridge to the native (Android) exact-alarm + foreground-service that plays
/// the FULL adhan at prayer time — even when the app is killed. The notification
/// path can only play a short channel sound, so this is the only way to auto-play
/// a multi-minute adhan in the background.
///
/// Android-only. Every method is a safe no-op on other platforms and when the
/// native channel isn't reachable — notably a background isolate (the weekly
/// refresh), where the MainActivity-registered channel doesn't exist, so a
/// [MissingPluginException] is swallowed and the caller keeps the
/// notification-sound fallback.
class AdhanAudioAlarms {
  static const MethodChannel _channel = MethodChannel('com.zikr.mapp/adhan_alarm');

  /// Arms an exact alarm at [when] that plays the `res/raw/<rawRes>` clip.
  /// [title]/[body]/[stopLabel] are the (localized) texts for the ongoing
  /// playback notification and its Stop action.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String rawRes,
    required String title,
    required String body,
    required String stopLabel,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('schedule', {
        'id': id,
        'triggerAtMillis': when.millisecondsSinceEpoch,
        'rawRes': rawRes,
        'title': title,
        'body': body,
        'stopLabel': stopLabel,
      });
    } on MissingPluginException {
      // Background isolate — no native channel. Caller falls back to the
      // notification sound for this window.
    } catch (e) {
      AppLogger.warning(
        'Adhan audio alarm schedule failed (id=$id): $e',
        tag: 'AdhanAudioAlarms',
      );
    }
  }

  /// Cancels every armed adhan audio alarm. Called before re-arming a fresh
  /// window, and whenever full-adhan background mode is turned off.
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } on MissingPluginException {
      // ignore — see [schedule].
    } catch (e) {
      AppLogger.warning(
        'Adhan audio alarm cancelAll failed: $e',
        tag: 'AdhanAudioAlarms',
      );
    }
  }
}
