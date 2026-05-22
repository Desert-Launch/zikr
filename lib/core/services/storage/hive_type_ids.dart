/// Reserved Hive `typeId`s — **never reuse a number**.
///
/// Each model declares `@HiveType(typeId: <const>)` referencing a value from
/// this file. Adding a new model: pick the next free id in the right band,
/// add a constant here, run the build_runner step in CLAUDE.md §12.
class HiveTypeIds {
  HiveTypeIds._();

  //   0–9    Core
  static const int user = 0;
  static const int authToken = 1;
  static const int appSettings = 2;
  static const int themePref = 3;

  //   10–19  Quran
  static const int bookmark = 10;
  static const int lastRead = 11;
  static const int downloadTask = 12;
  static const int reciterPref = 13;

  //   20–29  Prayer
  static const int prayerSettings = 20;
  static const int prayerCache = 21;

  //   30–39  Azkar
  static const int azkarFavorite = 30;
  static const int azkarProgress = 31;

  //   40–49  Tasbih
  static const int tasbihCounter = 40;
  static const int tasbihHistory = 41;

  //   50–59  Reminders
  static const int reminder = 50;

  //   60–69  Mosques
  static const int favoriteMosque = 60;
  static const int mosquesCache = 61;

  //   70–79  Qibla
  static const int qiblaCalibration = 70;

  //   80–89  Khatma
  static const int khatmaPlan = 80;
  static const int khatmaProgress = 81;
  static const int khatmaDay = 82;
  static const int khatmaCompletion = 83;

  //   90–99  Settings
  static const int notificationsToggle = 90;

  //   100–109 Notifications
  static const int scheduledNotification = 100;
  static const int notificationLog = 101;

  //   110–119 Adhan
  static const int adhanPreference = 110;
}
