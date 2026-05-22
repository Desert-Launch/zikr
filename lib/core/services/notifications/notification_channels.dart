import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// All Android notification channels the app creates at boot.
///
/// Channel IDs are stable strings — never rename one without migrating
/// scheduled notifications, or Android keeps showing the old channel.
class AppNotificationChannels {
  AppNotificationChannels._();

  static const prayer = AndroidNotificationChannel(
    'prayer_channel',
    'Prayer Times',
    description: 'Notifications for the 5 daily prayers',
    importance: Importance.high,
    playSound: true,
  );

  static const azkar = AndroidNotificationChannel(
    'azkar_channel',
    'Daily Azkar',
    description: 'Morning / evening / sleep azkar reminders',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  /// Hourly tasbih is silent + low importance so it doesn't interrupt.
  static const hourly = AndroidNotificationChannel(
    'hourly_channel',
    'Hourly Tasbih',
    description: 'Quiet hourly zekr (08:00 — 22:00 only)',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  static const reminders = AndroidNotificationChannel(
    'reminders_channel',
    'Custom Reminders',
    description: 'Your own daily reminders',
    importance: Importance.defaultImportance,
  );

  /// Generic Quran-content reminders (Al-Mulk before sleep, Friday Al-Kahf,
  /// etc.). Separate channel so the user can mute it without losing prayer.
  static const quranReminders = AndroidNotificationChannel(
    'quran_reminders_channel',
    'Quran Reminders',
    description: 'Recommended daily Quranic readings',
    importance: Importance.defaultImportance,
  );

  /// All channels in registration order. [NotificationsService.init] iterates
  /// this list once at boot.
  static const List<AndroidNotificationChannel> all = [
    prayer,
    azkar,
    hourly,
    reminders,
    quranReminders,
  ];
}
