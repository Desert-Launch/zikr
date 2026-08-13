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
  ///
  /// [AudioAttributesUsage.alarm] puts the adhan on the device's ALARM volume
  /// slider rather than the notification one — matching the native full-adhan
  /// service (which uses `USAGE_ALARM`) so the two paths can't end up at
  /// different loudness, and so a silenced notification volume never mutes the
  /// call to prayer.
  ///
  /// Silent-motor variant, and the default: the adhan announces itself, so a
  /// buzz under it adds nothing unless the user asks for one.
  ///
  /// Vibration — like sound and audio attributes — is frozen when a channel is
  /// first created, and `AndroidNotificationDetails`' per-notification
  /// `enableVibration` cannot substitute for it: from API 26 on the channel
  /// decides and the per-notification flag is ignored. So the user-facing
  /// vibration toggle is a CHANNEL CHOICE, not a flag — see [adhanVibrate].
  static const adhan = AndroidNotificationChannel(
    'adhan_channel_v3',
    'Adhan',
    description: 'Call-to-prayer (adhan) alerts at each prayer time',
    importance: Importance.max,
    playSound: true,
    enableVibration: false,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  /// Vibrating twin of [adhan], selected when `MAdhanSettings.vibrate` is on.
  ///
  /// Identical in every other respect — same alarm audio attributes, so both
  /// paths stay on the alarm volume and can't drift to different loudness. It
  /// must be a separate id rather than a mutation of [adhan] because Android
  /// freezes vibration at creation; both channels are created at boot and both
  /// are kept, since the user can flip back at any time.
  static const adhanVibrate = AndroidNotificationChannel(
    'adhan_channel_v3_vib',
    'Adhan (vibrate)',
    description: 'Call-to-prayer (adhan) alerts with vibration',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  /// Silent companion for the adhan when the FULL audio is played by the native
  /// foreground service (Android background full-adhan mode). Still a max-importance
  /// heads-up, but no channel sound — the MediaPlayer service provides the audio,
  /// so we must not also fire the short clip.
  static const adhanSilent = AndroidNotificationChannel(
    'adhan_silent_channel',
    'Adhan (full audio)',
    description:
        'Adhan alert shown while the full adhan plays in the background',
    importance: Importance.max,
    playSound: false,
    enableVibration: false,
  );

  /// Vibrating twin of [adhanSilent]. Still soundless — the foreground service
  /// owns the audio — but it buzzes.
  ///
  /// Needed because Android background full-adhan is the DEFAULT: on that path
  /// the prayer notification goes out on the silent companion rather than
  /// [adhan] / a per-voice channel, so without this twin the vibration toggle
  /// would be inert for most Android users.
  static const adhanSilentVibrate = AndroidNotificationChannel(
    'adhan_silent_channel_vib',
    'Adhan (full audio, vibrate)',
    description:
        'Adhan alert with vibration, shown while the full adhan plays in the '
        'background',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
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
    description: 'Reminders to send salawat upon the Prophet ﷺ',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('salah_3la_mohamed'),
  );

  /// Alarm-attributed twin of [salawat], selected when the user asks to be
  /// reminded even while the phone is silenced.
  ///
  /// [AudioAttributesUsage.alarm] is the same technique the adhan uses: an
  /// alarm-usage sound follows the ALARM volume and plays through ring/silent,
  /// where a notification-usage one is muted. High importance so it still
  /// surfaces a heads-up. Audio attributes are frozen at channel creation, so
  /// this has to be a separate id — both twins are created at boot and kept,
  /// and the toggle routes between them.
  ///
  /// Android only. iOS cannot sound through Silent mode without the
  /// critical-alert entitlement, which this app does not hold.
  static const salawatAlarm = AndroidNotificationChannel(
    'salawat_channel_alarm',
    'Salawat Reminder (through silent)',
    description:
        'Reminders to send salawat upon the Prophet ﷺ, audible while the '
        'phone is silenced',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('salah_3la_mohamed'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
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
    adhanVibrate,
    adhanSilent,
    adhanSilentVibrate,
    adhanPre,
    hourly,
    salawat,
    salawatAlarm,
    reminders,
    quranReminders,
    downloads,
  ];

  /// Channel ids replaced by a re-created version above. A channel's sound,
  /// vibration and audio attributes are immutable once Android has created it,
  /// so changing any of them means publishing a new id — and deleting the old
  /// one, or it lingers forever in the app's notification settings as a dead
  /// duplicate. [NotificationsService.init] deletes these once at boot.
  static const List<String> legacyIds = ['adhan_channel', 'adhan_channel_v2'];

  /// Prefix of the per-voice adhan channels created by
  /// [NotificationsService.createVoiceChannel] before they moved to the alarm
  /// stream. Their ids embed the voice id, so they're matched by prefix rather
  /// than listed; see `AdhanScheduler._resolveChannel` for the current naming.
  static const String legacyVoiceChannelPrefix = 'adhan_';
}
