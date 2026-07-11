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
  static const String radioBase = '/radio/';
  static const String liveBase = '/live/';
  static const String azkarBase = '/azkar/';
  static const String tasbihBase = '/tasbih/';
  static const String remindersBase = '/reminders/';
  static const String mosquesBase = '/mosques/';
  static const String qiblaBase = '/qibla/';
  static const String khatmaBase = '/khatma/';
  static const String settingsBase = '/settings/';
  static const String legalBase = '/legal/';
}

class AdhanRoutes {
  AdhanRoutes._();

  /// Sub-route within the adhan module ('/adhan/').
  static const String notifications = '/notifications';
  static const String picker = '/picker';

  static String overview() => RoutesNames.adhanBase;
  static String notificationsScreen() =>
      '${RoutesNames.adhanBase}notifications';
  static String voicePicker(String prayerKey) =>
      '${RoutesNames.adhanBase}picker?prayer=$prayerKey';
}

class RadioRoutes {
  RadioRoutes._();

  /// Sub-route within the radio module ('/radio/').
  static const String home = '/';

  static String fullHome() => RoutesNames.radioBase;
}

class LiveRoutes {
  LiveRoutes._();

  /// Channel-picker sub-route within the live module ('/live/').
  static const String home = '/';

  /// Player sub-route ('/live/player') — takes a `channel` query param.
  static const String player = '/player';

  static String fullHome() => RoutesNames.liveBase;

  /// Player for a specific channel by its selection [channelId] (e.g. 'makkah').
  static String playerFor(String channelId) =>
      '${RoutesNames.liveBase}player?channel=$channelId';
}

class QuranRoutes {
  QuranRoutes._();

  static const String surahList = '/';
  static const String reader = '/reader';
  static const String reciterPicker = '/reciter';
  static const String settings = '/settings';
  static const String reciterDownloads = '/reciter-downloads';
  static const String reciterSurahs = '/reciter-surahs';
  static const String bookmarks = '/bookmarks';
  static const String search = '/search';
  static const String tafsir = '/tafsir';
  static const String tafsirLibrary = '/tafsir-library';

  static String fullSurahList() => RoutesNames.quranBase;
  static String readerFromPage(int page) =>
      '${RoutesNames.quranBase}reader?page=$page';
  static String readerFromAyah(int surah, int ayah) =>
      '${RoutesNames.quranBase}reader?surah=$surah&ayah=$ayah';
  static String fullReciterPicker() => '${RoutesNames.quranBase}reciter';
  static String fullSettings() => '${RoutesNames.quranBase}settings';
  static String fullReciterDownloads() =>
      '${RoutesNames.quranBase}reciter-downloads';
  static String reciterSurahsFor(String reciterId) =>
      '${RoutesNames.quranBase}reciter-surahs?reciter=$reciterId';
  static String fullBookmarks() => '${RoutesNames.quranBase}bookmarks';
  static String fullSearch() => '${RoutesNames.quranBase}search';
  static String tafsirForAyah(int surah, int ayah) =>
      '${RoutesNames.quranBase}tafsir?surah=$surah&ayah=$ayah';
  static String fullTafsirLibrary() => '${RoutesNames.quranBase}tafsir-library';
}

class AzkarRoutes {
  AzkarRoutes._();

  static const String home = '/';
  static const String other = '/other';
  static const String category = '/category';
  static const String player = '/player';
  static const String favorites = '/favorites';

  static String fullHome() => RoutesNames.azkarBase;
  static String fullOther() => '${RoutesNames.azkarBase}other';
  static String fullCategory(String categoryId) =>
      '${RoutesNames.azkarBase}category?category=$categoryId';
  static String fullPlayer(String categoryId, {int item = 0}) =>
      '${RoutesNames.azkarBase}player?category=$categoryId&item=$item';
  static String fullFavorites() => '${RoutesNames.azkarBase}favorites';
}

class TasbihRoutes {
  TasbihRoutes._();

  static const String counter = '/';
  static const String history = '/history';
  static const String hourly = '/hourly';
  static const String salawat = '/salawat';

  static String fullCounter() => RoutesNames.tasbihBase;
  static String fullHistory() => '${RoutesNames.tasbihBase}history';
  static String fullHourly() => '${RoutesNames.tasbihBase}hourly';
  static String fullSalawat() => '${RoutesNames.tasbihBase}salawat';
}

class RemindersRoutes {
  RemindersRoutes._();

  static const String list = '/';
  static const String form = '/form';

  static String fullList() => RoutesNames.remindersBase;
  static String fullForm({String? id}) =>
      '${RoutesNames.remindersBase}form${id != null ? '?id=$id' : ''}';
}

class QiblaRoutes {
  QiblaRoutes._();

  static const String compass = '/';

  static String fullCompass() => RoutesNames.qiblaBase;
}

class KhatmaRoutes {
  KhatmaRoutes._();

  static const String home = '/';
  static const String plans = '/plans';
  static const String wirds = '/wirds';
  static const String tracker = '/tracker';
  static const String completed = '/completed';
  static const String history = '/history';

  static String fullHome() => RoutesNames.khatmaBase;
  static String fullPlans() => '${RoutesNames.khatmaBase}plans';
  static String fullWirds(int planId) =>
      '${RoutesNames.khatmaBase}wirds?plan=$planId';
  static String fullTracker() => '${RoutesNames.khatmaBase}tracker';
  static String fullCompleted() => '${RoutesNames.khatmaBase}completed';
  static String fullHistory() => '${RoutesNames.khatmaBase}history';
}

class LegalRoutes {
  LegalRoutes._();

  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String about = '/about';

  static String fullPrivacy() => '${RoutesNames.legalBase}privacy';
  static String fullTerms() => '${RoutesNames.legalBase}terms';
  static String fullAbout() => '${RoutesNames.legalBase}about';
}

class OnboardingRoutes {
  OnboardingRoutes._();

  static const String language = '/';
  static const String pager = '/pager';
  static const String location = '/location';

  static String fullLanguage() => RoutesNames.onboardingBase;
  static String fullPager() => '${RoutesNames.onboardingBase}pager';
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
  static String fullReset(String email, String otp) =>
      '${RoutesNames.authBase}reset?email=${Uri.encodeQueryComponent(email)}&otp=${Uri.encodeQueryComponent(otp)}';
  static String fullSuccess() => '${RoutesNames.authBase}success';
}
