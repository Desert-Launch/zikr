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

  /// Adhan call-to-prayer alerts. Max importance so it surfaces a heads-up
  /// even while idle. Default device sound until a bundled clip channel is
  /// created for the selected voice (see
  /// [NotificationsService.createVoiceChannel]).
  static const adhan = AndroidNotificationChannel(
    'adhan_channel',
    'Adhan',
    description: 'Call-to-prayer (adhan) alerts at each prayer time',
    importance: Importance.max,
    playSound: true,
  );

  /// Silent companion for the adhan when the FULL audio is played by the native
  /// foreground service (Android background full-adhan mode). Still a max-importance
  /// heads-up, but no channel sound — the MediaPlayer service provides the audio,
  /// so we must not also fire the short clip.
  static const adhanSilent = AndroidNotificationChannel(
    'adhan_silent_channel',
    'Adhan (full audio)',
    description: 'Adhan alert shown while the full adhan plays in the background',
    importance: Importance.max,
    playSound: false,
    enableVibration: false,
  );

  /// Silent companion channel for the optional "X minutes before" reminder —
  /// no sound, just a heads-up.
  static const adhanPre = AndroidNotificationChannel(
    'adhan_pre_channel',
    'Prayer Reminder (before)',
    description: 'Optional reminder a few minutes before each prayer',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
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

  /// Salawat-upon-the-Prophet reminders. Plays a short bundled clip
  /// (`res/raw/salah_3la_mohamed.mp3`) so it's audibly distinct from the silent
  /// hourly tasbih. Default importance keeps it gentle but audible. Channel
  /// sound is immutable once created — never change [id] or the clip silently.
  static const salawat = AndroidNotificationChannel(
    'salawat_channel',
    'Salawat Reminder',
    description: 'Reminders to send salawat upon the Prophet ﷺ (08:30 — 22:30)',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('salah_3la_mohamed'),
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

  /// Ongoing progress notification while reciter audio downloads run. Low
  /// importance + silent so live progress updates never buzz or pop a heads-up.
  static const downloads = AndroidNotificationChannel(
    'downloads_channel',
    'Downloads',
    description: 'Quran audio download progress',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  /// All channels in registration order. [NotificationsService.init] iterates
  /// this list once at boot.
  static const List<AndroidNotificationChannel> all = [
    prayer,
    azkar,
    adhan,
    adhanSilent,
    adhanPre,
    hourly,
    salawat,
    reminders,
    quranReminders,
    downloads,
  ];
}
