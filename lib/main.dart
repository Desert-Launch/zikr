import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/cubits/cb_theme.dart';
import 'package:quran/core/cubits/s_theme.dart';
import 'package:quran/core/data/models/m_app_settings.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/routes/app_module.dart';
import 'package:quran/core/theme/app_themes.dart';
import 'package:quran/modules/auth/data/models/m_auth_token.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_download.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_preference.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_background.dart';
import 'package:quran/modules/adhan/services/adhan_bootstrap.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_progress.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_completion.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_cache.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_settings.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/data/models/m_reciter_pref.dart';
import 'package:quran/modules/quran/data/sources/local/quran_hive_registrar.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/settings/data/models/m_theme_pref.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.init();
  AppLogger.info('Boot start', tag: 'main');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await LocalizeAndTranslate.init(
    supportedLocales: const [Locale('ar'), Locale('en')],
    defaultType: LocalizationDefaultType.asDefined,
    assetLoader: const AssetLoaderRootBundleJson('assets/lang/'),
  );

  await Hive.initFlutter();
  QuranHiveRegistrar.registerAdapters();

  // Open every persisted box before runApp so cubit reads are synchronous.
  await Hive.openBox<MBookmark>('quran_bookmarks');
  await Hive.openBox<MLastRead>('quran_last_read');
  await Hive.openBox<MReciterPref>('quran_reciter_pref');
  await Hive.openBox<String>('quran_reader_settings');
  await Hive.openBox<dynamic>('quran_playback_prefs');
  await Hive.openBox<MThemePref>('app_theme_pref');
  await Hive.openBox<MAppSettings>('app_settings');
  await Hive.openBox<MUser>('app_user');
  await Hive.openBox<MAuthToken>('app_auth_token');
  await Hive.openBox<MPrayerSettings>('prayer_settings');
  await Hive.openBox<MPrayerCache>('prayer_cache');
  await Hive.openBox<String>('prayer_timings_cache');
  await Hive.openBox<String>('last_location');
  await Hive.openBox<MAdhanPreference>('adhan_preference');
  await Hive.openBox<MAdhanSettings>('adhan_settings');
  await Hive.openBox<MAdhanDownload>('adhan_downloads');
  await Hive.openBox<MAzkarFavorite>('azkar_favorites');
  await Hive.openBox<MAzkarProgress>('azkar_progress');
  await Hive.openBox<MTasbihCounter>('tasbih_counter');
  await Hive.openBox<MTasbihHistory>('tasbih_history');
  await Hive.openBox<MReminder>('reminders');
  await Hive.openBox<MKhatmaPlan>('khatma_plan');
  await Hive.openBox<MKhatmaDay>('khatma_days');
  await Hive.openBox<MKhatmaCompletion>('khatma_completions');

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.app.quran.audio',
    androidNotificationChannelName: 'Quran Recitation',
    androidNotificationOngoing: true,
  );

  AppLogger.info('Boot done — runApp', tag: 'main');
  runApp(
    ModularApp(
      module: AppModule(),
      child: const LocalizedApp(child: _Root()),
    ),
  );
}

/// Re-requests the OS notification permission for returning users whose adhan
/// is enabled but who never granted it (completed onboarding on a build that
/// didn't ask, or tapped "Don't Allow"). New users are handled by the
/// onboarding flow, so this is skipped until onboarding is done to avoid
/// prompting over it. Without the permission, [AdhanScheduler.reschedule]
/// silently schedules nothing.
Future<void> _ensureAdhanNotificationPermission() async {
  if (!Modular.get<BoxAppSettings>().current().hasSeenOnboarding) return;
  if (!Modular.get<BoxAdhanSettings>().current().enabled) return;
  final notifications = Modular.get<NotificationsService>();
  if (await notifications.hasPermission()) return;
  await notifications.requestPermission();
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> with WidgetsBindingObserver {
  /// Throttle for resume-triggered reschedules (keeps the advance window fresh
  /// without churning the schedule on every app switch).
  DateTime? _lastResumeReschedule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load theme + auth state in parallel before the first frame paints.
    Modular.get<CBTheme>().load();
    Modular.get<CBAuth>().bootstrap();
    // Wire notification channels + tap router (silent if not granted yet),
    // then re-register reminder alarms so schedules survive reboots / tz changes,
    // run the one-time adhan bootstrap, and rebuild the rolling adhan window.
    Modular.get<NotificationsService>().init().then((_) async {
      await Modular.get<CBReminders>().rescheduleAll();
      await Modular.get<AdhanBootstrap>().run();
      // Returning users who finished onboarding on an older build may never
      // have been asked for the notification permission — without it adhan
      // scheduling silently no-ops. Re-ask once here (new users are prompted
      // during onboarding, so this is gated on hasSeenOnboarding inside).
      await _ensureAdhanNotificationPermission();
      // Rebuild the rolling adhan window on every cold start so scheduling
      // never depends solely on opening Home or an app-resume event — the
      // resume callback does NOT fire on the initial launch. Cached location
      // only (no premature GPS prompt); Home requests a live fix and
      // reschedules again on success.
      await Modular.get<AdhanScheduler>().reschedule(useCachedLocation: true);
      // Arm the weekly Saturday background refresh (Android), and the
      // best-effort iOS background refresh.
      await initAdhanBackground();
      await initIosBackground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Rebuild the advance window on resume so it stays fresh between opens —
    // the reliable path on iOS (and a useful backstop on Android). Throttled.
    final now = DateTime.now();
    final last = _lastResumeReschedule;
    if (last != null && now.difference(last) < const Duration(hours: 6)) return;
    _lastResumeReschedule = now;
    Modular.get<AdhanScheduler>().reschedule();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return BlocBuilder<CBTheme, STheme>(
          bloc: Modular.get<CBTheme>(),
          builder: (_, __) {
            return MaterialApp.router(
              title: 'قرآن',
              debugShowCheckedModeBanner: false,
              theme: buildLightTheme(),
              themeMode: ThemeMode.light,
              routerConfig: Modular.routerConfig,
              localizationsDelegates: LocalizeAndTranslate.delegates,
              supportedLocales: LocalizeAndTranslate.getLocals(),
            );
          },
        );
      },
    );
  }
}
