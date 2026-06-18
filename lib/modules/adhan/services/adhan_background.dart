import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_router.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_preference.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_cache.dart';
import 'package:quran/modules/prayer/data/datasources/remote/ds_remote_prayer.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/prayer/data/repos/r_impl_prayer.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_times.dart';
import 'package:quran/modules/quran/data/sources/local/quran_hive_registrar.dart';

/// Weekly background refresh of the adhan schedule (Android only).
///
/// `android_alarm_manager_plus` fires [adhanWeeklyAlarmCallback] in a fresh
/// background isolate at the next Saturday 00:00 — even when the app is killed
/// — and the callback re-arms the following Saturday. iOS can't run code on a
/// schedule when killed; it relies on rescheduling on app open instead.
const int _weeklyAlarmId = 920001;

/// Initialises the alarm plugin and arms the first weekly refresh. Call once
/// from `main` (no-op off Android).
Future<void> initAdhanBackground() async {
  if (!Platform.isAndroid) return;
  try {
    await AndroidAlarmManager.initialize();
    await armWeeklyAdhanRefresh();
  } catch (e, st) {
    AppLogger.error(
      'Adhan background init failed',
      error: e,
      stackTrace: st,
      tag: 'AdhanBackground',
    );
  }
}

/// Arms (or re-arms) the weekly refresh at the next Saturday 00:00. Idempotent:
/// the fixed [_weeklyAlarmId] means a re-arm overwrites the pending alarm.
Future<void> armWeeklyAdhanRefresh() async {
  if (!Platform.isAndroid) return;
  final when = _nextSaturdayMidnight(DateTime.now());
  await AndroidAlarmManager.oneShotAt(
    when,
    _weeklyAlarmId,
    adhanWeeklyAlarmCallback,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: true,
  );
}

/// The next Saturday at 00:00 strictly in the future (today, if Saturday,
/// rolls to next week).
DateTime _nextSaturdayMidnight(DateTime now) {
  final daysUntilSat = (DateTime.saturday - now.weekday) % 7; // 0 = today is Sat
  final candidate = DateTime(now.year, now.month, now.day + daysUntilSat);
  return candidate.isAfter(now)
      ? candidate
      : DateTime(now.year, now.month, now.day + 7);
}

/// Runs in a background isolate. Rebuilds the adhan window from the last-known
/// location (no live GPS here) using the cache-first repo, then re-arms next
/// week. Everything the scheduler needs is re-initialised because the isolate
/// shares no state with the app.
@pragma('vm:entry-point')
Future<void> adhanWeeklyAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
  AppLogger.info('Weekly adhan alarm fired', tag: 'AdhanBackground');
  try {
    await Hive.initFlutter();
    QuranHiveRegistrar.registerAdapters();
    await _openBoxes();
    await LocalizeAndTranslate.init(
      supportedLocales: const [Locale('ar'), Locale('en')],
      defaultType: LocalizationDefaultType.asDefined,
      assetLoader: const AssetLoaderRootBundleJson('assets/lang/'),
    );

    final notifications = NotificationsService(NotificationRouter());
    await notifications.init();

    final scheduler = AdhanScheduler(
      notifications: notifications,
      location: DSLocation(),
      getTimes: UCGetPrayerTimes(
        RImplPrayer(remote: DSRemotePrayer(), cache: DSPrayerCache()),
      ),
      prayerSettings: BoxPrayerSettings(),
      adhanSettings: BoxAdhanSettings(),
      adhanPrefs: BoxAdhanPreference(),
      local: DSLocalAdhan(),
      lastLocation: DSLastLocation(),
    );
    await scheduler.reschedule(useCachedLocation: true);
    AppLogger.info('Weekly adhan refresh done', tag: 'AdhanBackground');
  } catch (e, st) {
    AppLogger.error(
      'Weekly adhan refresh failed',
      error: e,
      stackTrace: st,
      tag: 'AdhanBackground',
    );
  } finally {
    // Always re-arm, even on failure, so a single bad run doesn't end the loop.
    await armWeeklyAdhanRefresh();
  }
}

Future<void> _openBoxes() async {
  Future<void> open<T>(String name) async {
    if (!Hive.isBoxOpen(name)) await Hive.openBox<T>(name);
  }

  await open<MPrayerSettings>('prayer_settings');
  await open<MAdhanSettings>('adhan_settings');
  await open<MAdhanPreference>('adhan_preference');
  await open<String>('prayer_timings_cache');
  await open<String>('last_location');
}
