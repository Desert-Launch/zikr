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
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';
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
import 'package:quran/modules/onboarding/onboarding_module.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_cache.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/prayer_module.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/qibla/qibla_module.dart';
import 'package:quran/modules/quran/quran_module.dart';
import 'package:quran/modules/reminders/data/sources/local/box_reminders.dart';
import 'package:quran/modules/reminders/presentation/cubits/cb_reminders.dart';
import 'package:quran/modules/reminders/reminders_module.dart';
import 'package:quran/modules/settings/data/sources/local/box_theme_pref.dart';
import 'package:quran/modules/settings/settings_module.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
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
        notifications: i.get<NotificationsService>(),
      ),
    );
    i.addSingleton<CBAdhanPlayer>(
      () => CBAdhanPlayer(
        local: i.get<DSLocalAdhan>(),
        prefs: i.get<BoxAdhanPreference>(),
        localeTag: 'ar-EG',
      ),
    );
    i.addSingleton<CBTasbih>(
      () => CBTasbih(
        counterBox: i.get<BoxTasbihCounter>(),
        historyBox: i.get<BoxTasbihHistory>(),
        hourly: i.get<DSHourlyTasbih>(),
      ),
    );
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
