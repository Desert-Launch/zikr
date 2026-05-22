/// Centralised, type-safe route names for the whole app.
///
/// Every route literal lives here — UI code calls `Modular.to.navigate(...)`,
/// never a raw string. Helpers like `readerFromAyah(2, 255)` build URLs with
/// query params.
class RoutesNames {
  RoutesNames._();

  static const String splash = '/';

  // Module base paths (mounted in [AppModule.routes]).
  static const String authBase = '/auth/';
  static const String onboardingBase = '/onboarding/';
  static const String homeBase = '/home/';
  static const String quranBase = '/quran/';
  static const String prayerBase = '/prayer/';
  static const String adhanBase = '/adhan/';
  static const String azkarBase = '/azkar/';
  static const String tasbihBase = '/tasbih/';
  static const String remindersBase = '/reminders/';
  static const String mosquesBase = '/mosques/';
  static const String qiblaBase = '/qibla/';
  static const String khatmaBase = '/khatma/';
  static const String settingsBase = '/settings/';
  static const String legalBase = '/legal/';
}

class QuranRoutes {
  QuranRoutes._();

  static const String surahList = '/';
  static const String reader = '/reader';
  static const String reciterPicker = '/reciter';
  static const String downloads = '/downloads';
  static const String bookmarks = '/bookmarks';
  static const String search = '/search';

  static String fullSurahList() => RoutesNames.quranBase;
  static String readerFromPage(int page) => '${RoutesNames.quranBase}reader?page=$page';
  static String readerFromAyah(int surah, int ayah) =>
      '${RoutesNames.quranBase}reader?surah=$surah&ayah=$ayah';
  static String fullReciterPicker() => '${RoutesNames.quranBase}reciter';
  static String fullDownloads() => '${RoutesNames.quranBase}downloads';
  static String fullBookmarks() => '${RoutesNames.quranBase}bookmarks';
  static String fullSearch() => '${RoutesNames.quranBase}search';
}

class OnboardingRoutes {
  OnboardingRoutes._();

  static const String pager = '/';
  static const String language = '/language';
  static const String location = '/location';

  static String fullPager() => RoutesNames.onboardingBase;
  static String fullLanguage() => '${RoutesNames.onboardingBase}language';
  static String fullLocation() => '${RoutesNames.onboardingBase}location';
}

class HomeRoutes {
  HomeRoutes._();

  static const String dashboard = '/';

  static String fullDashboard() => RoutesNames.homeBase;
}

class SettingsRoutes {
  SettingsRoutes._();

  static const String main = '/';

  static String fullMain() => RoutesNames.settingsBase;
}

class AuthRoutes {
  AuthRoutes._();

  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot';
  static const String verifyOtp = '/otp';
  static const String resetPassword = '/reset';
  static const String registerSuccess = '/success';

  static String fullLogin() => RoutesNames.authBase;
  static String fullRegister() => '${RoutesNames.authBase}register';
  static String fullForgot() => '${RoutesNames.authBase}forgot';
  static String fullOtp(String email) =>
      '${RoutesNames.authBase}otp?email=${Uri.encodeQueryComponent(email)}';
  static String fullReset(String email) =>
      '${RoutesNames.authBase}reset?email=${Uri.encodeQueryComponent(email)}';
  static String fullSuccess() => '${RoutesNames.authBase}success';
}
