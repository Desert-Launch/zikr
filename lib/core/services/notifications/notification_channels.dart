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
  ///
  /// Still the channel used whenever the per-zekr audio is switched off, or
  /// when the hour's clip isn't bundled — see [hourlyZikr].
  static const hourly = AndroidNotificationChannel(
    'hourly_channel',
    'Hourly Tasbih',
    description: 'Quiet hourly zekr (08:00 — 22:00 only)',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  /// Prefix of the per-zekr hourly channels built by [hourlyZikr]. Their ids
  /// embed the clip's slug, so they're matched by prefix rather than listed.
  static const String hourlyZikrChannelPrefix = 'hourly_zikr_';

  /// Channel id for the hourly zekr whose clip is [soundSlug].
  ///
  /// The `_v1` suffix is the escape hatch for changing a clip later: a
  /// channel's sound is frozen when Android first creates it, so replacing
  /// `zikr_01_subhan_allah.mp3` with a different recording means bumping this
  /// to `_v2` and adding the old id to [legacyIds] — editing the file alone
  /// leaves every existing install playing the original.
  static String hourlyZikrChannelId(String soundSlug) =>
      '$hourlyZikrChannelPrefix${soundSlug}_v1';

  /// An audible hourly-zekr channel that plays the bundled clip [soundSlug]
  /// (an `android/app/src/main/res/raw/<soundSlug>.mp3`), labelled [name].
  ///
  /// One channel per zekr, because the sound lives on the channel and not on
  /// the notification — a single channel could only ever play one clip. They're
  /// created on demand by `DSHourlyTasbih` rather than at boot, so an install
  /// that never turns the audio on never grows ten entries in its notification
  /// settings, and deleted again when the user switches the audio back off.
  ///
  /// [name] is the zekr's own text so the ten entries are tellable apart in
  /// Android's per-channel settings, where the user can silence just one.
  ///
  /// Default importance rather than [Importance.low]: low is silent whatever
  /// the channel's sound says. Vibration stays off — this fires up to 15 times
  /// a day, and the clip is the point.
  static AndroidNotificationChannel hourlyZikr({
    required String soundSlug,
    required String name,
  }) => AndroidNotificationChannel(
    hourlyZikrChannelId(soundSlug),
    name,
    description: 'Hourly zekr reminder, read aloud',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(soundSlug),
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

  /// Silent twin of [salawat], used when the user asks to be reminded even
  /// while the phone is silenced.
  ///
  /// The obvious implementation — an alarm-attributed channel, which is what
  /// [salawatAlarm] was — does not survive contact with real devices: One UI's
  /// "Mute" mode drops app notification sounds whatever the channel's audio
  /// attributes say, so the reminder arrived silently on exactly the phones the
  /// toggle exists for (verified: alarm-usage channel, Do Not Disturb off,
  /// ALARM volume 11/15, and the OS never started a player).
  ///
  /// So the audio moved out of the channel: `ReminderSoundAlarms` arms a native
  /// alarm that plays the clip through MediaPlayer on the ALARM stream, which no
  /// OEM mutes, and this channel stays silent so the two can't double up. High
  /// importance keeps the heads-up banner the toggle implies.
  static const salawatSilent = AndroidNotificationChannel(
    'salawat_channel_silent',
    'Salawat Reminder (through silent)',
    description:
        'Reminders to send salawat upon the Prophet ﷺ, audible while the '
        'phone is silenced',
    importance: Importance.high,
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
    salawatSilent,
    reminders,
    quranReminders,
    downloads,
  ];

  /// Channel ids replaced by a re-created version above. A channel's sound,
  /// vibration and audio attributes are immutable once Android has created it,
  /// so changing any of them means publishing a new id — and deleting the old
  /// one, or it lingers forever in the app's notification settings as a dead
  /// duplicate. [NotificationsService.init] deletes these once at boot.
  static const List<String> legacyIds = [
    'adhan_channel',
    'adhan_channel_v2',
    // Alarm-attributed salawat channel, replaced by [salawatSilent] + the
    // app-played clip. Its sound never reached users on One UI, and a channel
    // that still exists keeps showing up in the app's notification settings.
    'salawat_channel_alarm',
  ];

  /// Prefix of the per-voice adhan channels created by
  /// [NotificationsService.createVoiceChannel] before they moved to the alarm
  /// stream. Their ids embed the voice id, so they're matched by prefix rather
  /// than listed; see `AdhanScheduler._resolveChannel` for the current naming.
  static const String legacyVoiceChannelPrefix = 'adhan_';
}
