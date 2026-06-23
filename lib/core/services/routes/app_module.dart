import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/cubits/cb_theme.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/mock_backend/mock_database.dart';
import 'package:quran/core/services/mock_backend/mock_interceptor.dart';
import 'package:quran/core/services/network/base_dio.dart';
import 'package:quran/core/services/notifications/notification_router.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/theme_manager.dart';
import 'package:quran/modules/adhan/adhan_module.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/datasources/remote/ds_remote_adhan.dart';
import 'package:quran/modules/adhan/data/repos/r_impl_adhan.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_download.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_delete_adhan_voice.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_download_adhan_voice.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_fetch_adhan_catalog.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_download.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_bootstrap.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/auth/auth_module.dart';
import 'package:quran/modules/auth/data/datasources/remote/ds_remote_auth.dart';
import 'package:quran/modules/auth/data/repos/r_impl_auth.dart';
import 'package:quran/modules/auth/data/sources/local/box_auth_token.dart';
import 'package:quran/modules/auth/data/sources/local/box_user.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';
import 'package:quran/modules/auth/domain/usecases/uc_get_current_user.dart';
import 'package:quran/modules/auth/domain/usecases/uc_is_logged_in.dart';
import 'package:quran/modules/auth/domain/usecases/uc_logout.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/azkar/azkar_module.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_favorite.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/home/home_module.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_completion.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_day.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_plan.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/khatma_module.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/legal/legal_module.dart';
import 'package:quran/modules/live/live_module.dart';
import 'package:quran/modules/onboarding/onboarding_module.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_last_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_cache.dart';
import 'package:quran/modules/prayer/data/datasources/remote/ds_remote_prayer.dart';
import 'package:quran/modules/prayer/data/repos/r_impl_prayer.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/repos/r_prayer.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_prayer_times.dart';
import 'package:quran/modules/prayer/prayer_module.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/qibla/qibla_module.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/repos/r_impl_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_daily_verse.dart';
import 'package:quran/modules/quran/quran_module.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';
import 'package:quran/modules/radio/radio_module.dart';
import 'package:quran/modules/reminders/data/sources/local/box_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/reminders_module.dart';
import 'package:quran/modules/settings/data/sources/local/box_theme_pref.dart';
import 'package:quran/modules/settings/settings_module.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_salawat.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/tasbih_module.dart';
import 'package:quran/presentation/sn_splash.dart';

/// Root [Module]. Hosts app-wide singletons and mounts all feature modules.
///
/// CBAuth is needed at app boot (before any feature route is navigated), so
/// its full dependency chain — boxes → DS → repo → use cases — lives here.
/// AuthModule registers only the per-screen form cubits and the use cases
/// that exclusively serve them (login/register/forgot/reset).
class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Hive box singletons (shared across modules)
    i.addSingleton<BoxAppSettings>(BoxAppSettings.new);
    i.addSingleton<BoxThemePref>(BoxThemePref.new);
    i.addSingleton<BoxUser>(BoxUser.new);
    i.addSingleton<BoxAuthToken>(BoxAuthToken.new);
    i.addSingleton<BoxPrayerSettings>(BoxPrayerSettings.new);
    i.addSingleton<BoxPrayerCache>(BoxPrayerCache.new);
    i.addSingleton<BoxAdhanPreference>(BoxAdhanPreference.new);
    i.addSingleton<BoxAdhanSettings>(BoxAdhanSettings.new);
    i.addSingleton<BoxAdhanDownload>(BoxAdhanDownload.new);
    i.addSingleton<BoxAzkarFavorite>(BoxAzkarFavorite.new);
    i.addSingleton<BoxAzkarProgress>(BoxAzkarProgress.new);
    i.addSingleton<BoxTasbihCounter>(BoxTasbihCounter.new);
    i.addSingleton<BoxTasbihHistory>(BoxTasbihHistory.new);
    i.addSingleton<BoxReminders>(BoxReminders.new);
    i.addSingleton<BoxKhatmaPlan>(BoxKhatmaPlan.new);
    i.addSingleton<BoxKhatmaDay>(BoxKhatmaDay.new);
    i.addSingleton<BoxKhatmaCompletion>(BoxKhatmaCompletion.new);

    // Azkar data source
    i.addSingleton<DSLocalAzkar>(DSLocalAzkar.new);

    // Hourly tasbih scheduler — depends on the notifications service below.
    i.addSingleton<DSHourlyTasbih>(
      () => DSHourlyTasbih(i.get<NotificationsService>()),
    );

    // Adhan
    i.addSingleton<DSLocalAdhan>(DSLocalAdhan.new);
    i.addSingleton<DSLocalKhatma>(DSLocalKhatma.new);

    // Notifications + location (cross-cutting infra)
    i.addSingleton<NotificationRouter>(NotificationRouter.new);
    i.addSingleton<NotificationsService>(
      () => NotificationsService(i.get<NotificationRouter>()),
    );
    i.addSingleton<DSLocation>(DSLocation.new);

    // Mock backend — registered before BaseDio so the interceptor is wired in.
    i.addSingleton<MockDatabase>(MockDatabase.new);
    i.addSingleton<MockInterceptor>(
      () => MockInterceptor(i.get<MockDatabase>()),
    );

    // Network
    i.addSingleton<BaseDio>(BaseDio.new);

    // Auth data + repo (shared with AuthModule's submodule bindings)
    i.addSingleton<DSRemoteAuth>(() => DSRemoteAuth(i.get<BaseDio>()));
    i.addSingleton<RAuth>(
      () => RImplAuth(
        remote: i.get<DSRemoteAuth>(),
        userBox: i.get<BoxUser>(),
        tokenBox: i.get<BoxAuthToken>(),
      ),
    );

    // Use cases consumed by CBAuth at boot.
    i.add<UCIsLoggedIn>(() => UCIsLoggedIn(i.get<RAuth>()));
    i.add<UCGetCurrentUser>(() => UCGetCurrentUser(i.get<RAuth>()));
    i.add<UCLogout>(() => UCLogout(i.get<RAuth>()));

    // Prayer data + repo (Aladhan remote API). DSRemotePrayer owns its own
    // Dio, so it does not depend on BaseDio.
    i.addSingleton<DSRemotePrayer>(DSRemotePrayer.new);
    i.addSingleton<DSPrayerCache>(DSPrayerCache.new);
    i.addSingleton<DSLastLocation>(DSLastLocation.new);
    i.addSingleton<RPrayer>(
      () => RImplPrayer(
        remote: i.get<DSRemotePrayer>(),
        cache: i.get<DSPrayerCache>(),
      ),
    );
    i.add<UCGetPrayerTimes>(() => UCGetPrayerTimes(i.get<RPrayer>()));

    // Adhan catalog + download (own Dio, falls back to bundled adhans.json).
    i.addSingleton<DSRemoteAdhan>(DSRemoteAdhan.new);
    i.addSingleton<RAdhan>(
      () => RImplAdhan(
        remote: i.get<DSRemoteAdhan>(),
        local: i.get<DSLocalAdhan>(),
        downloads: i.get<BoxAdhanDownload>(),
      ),
    );
    i.add<UCFetchAdhanCatalog>(() => UCFetchAdhanCatalog(i.get<RAdhan>()));
    i.add<UCDownloadAdhanVoice>(() => UCDownloadAdhanVoice(i.get<RAdhan>()));
    i.add<UCDeleteAdhanVoice>(() => UCDeleteAdhanVoice(i.get<RAdhan>()));

    // Rolling adhan-notification scheduler + first-launch bootstrap.
    i.addSingleton<AdhanScheduler>(
      () => AdhanScheduler(
        notifications: i.get<NotificationsService>(),
        location: i.get<DSLocation>(),
        getTimes: i.get<UCGetPrayerTimes>(),
        prayerSettings: i.get<BoxPrayerSettings>(),
        adhanSettings: i.get<BoxAdhanSettings>(),
        adhanPrefs: i.get<BoxAdhanPreference>(),
        local: i.get<DSLocalAdhan>(),
        lastLocation: i.get<DSLastLocation>(),
      ),
    );
    i.addSingleton<AdhanBootstrap>(
      () => AdhanBootstrap(
        repo: i.get<RAdhan>(),
        settings: i.get<BoxAdhanSettings>(),
        prefs: i.get<BoxAdhanPreference>(),
        local: i.get<DSLocalAdhan>(),
        // Device locale (e.g. ar-EG, ar-SA, en-US) picks the regional default
        // adhan; defaultForLocale degrades gracefully for partial/unknown tags.
        localeTag:
            WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      ),
    );

    // App-wide cubits / managers
    i.addLazySingleton<ThemeManager>(ThemeManager.new);
    i.addSingleton<CBTheme>(() => CBTheme(i.get<BoxThemePref>()));
    i.addSingleton<CBAuth>(
      () => CBAuth(
        isLoggedIn: i.get<UCIsLoggedIn>(),
        currentUser: i.get<UCGetCurrentUser>(),
        logout: i.get<UCLogout>(),
      ),
    );
    i.addSingleton<CBPrayerTimes>(
      () => CBPrayerTimes(
        location: i.get<DSLocation>(),
        settings: i.get<BoxPrayerSettings>(),
        cache: i.get<BoxPrayerCache>(),
        scheduler: i.get<AdhanScheduler>(),
        getTimes: i.get<UCGetPrayerTimes>(),
      ),
    );
    // Verse-of-the-day for the home dashboard. Built with a dedicated
    // DSLocalQuran instance so it does not depend on QuranModule's scope
    // (home is loaded before any Quran route is mounted).
    i.addSingleton<CBDailyVerse>(
      () => CBDailyVerse(UCGetDailyVerse(RImplQuran(DSLocalQuran()))),
    );
    i.addSingleton<CBAdhanPlayer>(
      () => CBAdhanPlayer(
        local: i.get<DSLocalAdhan>(),
        prefs: i.get<BoxAdhanPreference>(),
        prayerSettings: i.get<BoxPrayerSettings>(),
        downloads: i.get<BoxAdhanDownload>(),
        localeTag:
            WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      ),
    );
    i.addSingleton<CBAdhanDownload>(
      () => CBAdhanDownload(
        download: i.get<UCDownloadAdhanVoice>(),
        delete: i.get<UCDeleteAdhanVoice>(),
        downloads: i.get<BoxAdhanDownload>(),
      ),
    );
    i.addSingleton<CBAdhanSettings>(
      () => CBAdhanSettings(
        adhanSettings: i.get<BoxAdhanSettings>(),
        prayerSettings: i.get<BoxPrayerSettings>(),
        adhanPrefs: i.get<BoxAdhanPreference>(),
        local: i.get<DSLocalAdhan>(),
        notifications: i.get<NotificationsService>(),
        scheduler: i.get<AdhanScheduler>(),
        fetchCatalog: i.get<UCFetchAdhanCatalog>(),
        downloadVoice: i.get<UCDownloadAdhanVoice>(),
        downloads: i.get<BoxAdhanDownload>(),
      ),
    );
    i.addSingleton<CBTasbih>(
      () => CBTasbih(
        counterBox: i.get<BoxTasbihCounter>(),
        historyBox: i.get<BoxTasbihHistory>(),
        hourly: i.get<DSHourlyTasbih>(),
      ),
    );
    i.addSingleton<CBSalawat>(
      () => CBSalawat(
        counterBox: i.get<BoxTasbihCounter>(),
        historyBox: i.get<BoxTasbihHistory>(),
      ),
    );
    // Live Quran radio player — app-wide so playback survives leaving the radio
    // screen. Lazy so its AudioPlayer is only created on first radio use.
    i.addLazySingleton<CBRadioPlayer>(CBRadioPlayer.new);
    i.addSingleton<CBReminders>(
      () => CBReminders(
        box: i.get<BoxReminders>(),
        notifications: i.get<NotificationsService>(),
      ),
    );
    i.addSingleton<CBKhatma>(
      () => CBKhatma(
        planBox: i.get<BoxKhatmaPlan>(),
        dayBox: i.get<BoxKhatmaDay>(),
        completionBox: i.get<BoxKhatmaCompletion>(),
        local: i.get<DSLocalKhatma>(),
        notifications: i.get<NotificationsService>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      RoutesNames.splash,
      transition: TransitionType.fadeIn,
      child: (_) => const SNSplash(),
    );
    r.module(RoutesNames.onboardingBase, module: OnboardingModule());
    r.module(RoutesNames.authBase, module: AuthModule());
    r.module(RoutesNames.homeBase, module: HomeModule());
    r.module(RoutesNames.quranBase, module: QuranModule());
    r.module(RoutesNames.prayerBase, module: PrayerModule());
    r.module(RoutesNames.adhanBase, module: AdhanModule());
    r.module(RoutesNames.radioBase, module: RadioModule());
    r.module(RoutesNames.liveBase, module: LiveModule());
    r.module(RoutesNames.azkarBase, module: AzkarModule());
    r.module(RoutesNames.tasbihBase, module: TasbihModule());
    r.module(RoutesNames.remindersBase, module: RemindersModule());
    r.module(RoutesNames.qiblaBase, module: QiblaModule());
    r.module(RoutesNames.khatmaBase, module: KhatmaModule());
    r.module(RoutesNames.legalBase, module: LegalModule());
    r.module(RoutesNames.settingsBase, module: SettingsModule());
  }
}

/// Simple modular observer for navigation logging.
class AppModularObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint(
      '[Nav] PUSH ${route.settings.name} (from: ${previousRoute?.settings.name})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint(
      '[Nav] POP ${route.settings.name} → ${previousRoute?.settings.name}',
    );
  }
}
