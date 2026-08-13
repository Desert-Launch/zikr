import 'dart:io';

import 'package:flutter/services.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Bridge to the native alarm that plays a reminder's clip on the ALARM stream
/// at the same minute its notification is posted.
///
/// # Why a notification channel isn't enough
///
/// Making a channel sound through silent mode is supposed to be a matter of
/// `audioAttributesUsage: alarm` — the sound then follows the ALARM volume,
/// which the ringer's silent/vibrate modes don't mute. Several OEMs ignore
/// that: on One UI, "Mute" drops app notification sounds regardless of the
/// channel's audio attributes (verified on a Galaxy Tab — alarm-usage channel,
/// no Do Not Disturb, alarm volume at 11/15, and the OS never started a
/// player). Audio the app plays itself is not subject to that gate, which is
/// why the full adhan is audible in Mute mode while the salawat clip was not.
///
/// So when "remind while silenced" is on, the notification goes out on a SILENT
/// channel and the sound comes from here instead. One notification, one sound,
/// on every OEM.
///
/// Android only, and every method is a safe no-op elsewhere or when the channel
/// is unreachable — notably a background isolate, where the
/// MainActivity-registered channel doesn't exist. The armed alarms simply stay
/// as the UI isolate or the boot receiver last left them.
class ReminderSoundAlarms {
  static const MethodChannel _channel = MethodChannel(
    'com.zikr.mapp/reminder_sound',
  );

  /// Arms [id] to play `res/raw/[rawRes]` daily at [hour]:[minute], replacing
  /// any alarm already armed under that id.
  ///
  /// The alarm re-arms itself for the following day when it fires, so the
  /// reminders keep sounding even if the app is never opened again. Returns
  /// false when nothing was armed (non-Android, unreachable channel) — the
  /// caller's cue that the notification is the only thing that will arrive.
  Future<bool> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String rawRes,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final armed = await _channel.invokeMethod<bool>('scheduleDaily', {
        'id': id,
        'hour': hour,
        'minute': minute,
        'rawRes': rawRes,
      });
      return armed ?? false;
    } on MissingPluginException {
      // Background isolate — no native channel; the existing alarms stand.
      return false;
    } catch (e) {
      AppLogger.warning(
        'Reminder sound schedule failed (id=$id): $e',
        tag: 'ReminderSoundAlarms',
      );
      return false;
    }
  }

  /// Cancels a single armed clip.
  Future<void> cancel(int id) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancel', {'id': id});
    } on MissingPluginException {
      // ignore — see [scheduleDaily].
    } catch (e) {
      AppLogger.warning(
        'Reminder sound cancel failed (id=$id): $e',
        tag: 'ReminderSoundAlarms',
      );
    }
  }

  /// Cancels every armed clip. Called before re-arming a fresh schedule and
  /// whenever the reminder is switched off.
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } on MissingPluginException {
      // ignore — see [scheduleDaily].
    } catch (e) {
      AppLogger.warning(
        'Reminder sound cancelAll failed: $e',
        tag: 'ReminderSoundAlarms',
      );
    }
  }

  /// Whether the OS still lets us schedule the exact alarms this depends on.
  ///
  /// False means Android 12+ with "Alarms & reminders" revoked: the clip then
  /// arrives a few minutes late (inexact alarm) rather than not at all, so this
  /// is for warning the user, not for gating the schedule.
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return false;
    try {
      final can = await _channel.invokeMethod<bool>('canScheduleExact');
      return can ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
