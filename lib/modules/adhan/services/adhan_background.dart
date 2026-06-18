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
import 'package:workmanager/workmanager.dart';

/// Weekly background refresh of the adhan schedule (Android only).
///
/// `android_alarm_manager_plus` fires [adhanWeeklyAlarmCallback] in a fresh
/// background isolate at the next Saturday 00:00 — even when the app is killed
/// — and the callback re-arms the following Saturday. iOS can't run code on a
/// schedule when killed; it relies on rescheduling on app open instead.
const int _weeklyAlarmId = 920001;

/// iOS BGTask identifier. Must match `BGTaskSchedulerPermittedIdentifiers` in
/// Info.plist and the `WorkmanagerPlugin.register…` call in AppDelegate.swift.
const String _iosTaskId = 'com.app.quran.adhanRefresh';

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

/// iOS only: registers a best-effort background refresh (BGAppRefreshTask via
/// workmanager). iOS decides when this actually runs and never on a schedule
/// you choose — the reliable iOS path is rescheduling on app open/resume. The
/// native side (Info.plist + AppDelegate) must register [_iosTaskId] or the
/// submit below is logged-and-ignored. Errors are swallowed so a missing
/// native registration can't crash startup.
Future<void> initIosBackground() async {
  if (!Platform.isIOS) return;
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _iosTaskId,
      _iosTaskId,
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(hours: 6),
    );
  } catch (e, st) {
    AppLogger.error(
      'iOS background init failed (best-effort)',
      error: e,
      stackTrace: st,
      tag: 'AdhanBackground',
    );
  }
}

/// workmanager entry point (iOS). Runs the shared reschedule and reports
/// success so iOS keeps scheduling future refreshes.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await runAdhanBackgroundReschedule();
    return true;
  });
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

/// Android alarm entry point. Rebuilds the adhan window, then re-arms next week
/// (even on failure, so one bad run doesn't end the loop).
@pragma('vm:entry-point')
Future<void> adhanWeeklyAlarmCallback() async {
  AppLogger.info('Weekly adhan alarm fired', tag: 'AdhanBackground');
  try {
    await runAdhanBackgroundReschedule();
  } finally {
    await armWeeklyAdhanRefresh();
  }
}

/// Rebuilds the adhan window from a fresh, headless isolate: re-initialises
/// Hive, localization and notifications (the isolate shares no state with the
/// app), then reschedules from the last-known location (no live GPS here) via
/// the cache-first repo. Shared by the Android alarm and the iOS background
/// task. Never throws.
Future<void> runAdhanBackgroundReschedule() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
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
    AppLogger.info('Background adhan refresh done', tag: 'AdhanBackground');
  } catch (e, st) {
    AppLogger.error(
      'Background adhan refresh failed',
      error: e,
      stackTrace: st,
      tag: 'AdhanBackground',
    );
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
