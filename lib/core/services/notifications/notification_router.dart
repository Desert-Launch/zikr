import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// Maps a [NotificationPayload] tap to a screen. Lives in its own class so
/// tests can swap it out and so each feature module doesn't have to know
/// about the notification API surface.
class NotificationRouter {
  NotificationRouter();

  void route(NotificationPayload payload) {
    AppLogger.info(
      'Notification tapped: ${payload.type}',
      tag: 'NotificationRouter',
    );
    switch (payload.type) {
      case 'prayer':
        Modular.to.navigate(RoutesNames.prayerBase);
      case 'adhan':
        // Route to the full-screen in-app alarm, which starts playback itself
        // via CBAdhanRinging → CBAdhanPlayer. The native full-screen paths
        // (AdhanAlarmActivity / AlarmKit) cover the killed-app case; this is
        // the foreground equivalent.
        final prayer = payload.data['prayer']?.toString();
        if (prayer != null && prayer.isNotEmpty) {
          Modular.to.pushNamed(AdhanRoutes.ringingScreen(prayer));
        } else {
          Modular.to.navigate(RoutesNames.prayerBase);
        }
      case 'azkar':
        final category = payload.data['category']?.toString();
        if (category != null && category.isNotEmpty) {
          Modular.to.navigate(AzkarRoutes.fullCategory(category));
        } else {
          Modular.to.navigate(RoutesNames.azkarBase);
        }
      case 'hourly':
        Modular.to.navigate(RoutesNames.tasbihBase);
      case 'salawat':
        Modular.to.navigate(TasbihRoutes.fullSalawat());
      case 'reminder':
        Modular.to.navigate(RoutesNames.remindersBase);
      case 'quran':
        final surah = payload.data['surah'];
        final ayah = payload.data['ayah'];
        if (surah is int && ayah is int) {
          Modular.to.pushNamed(QuranRoutes.readerFromAyah(surah, ayah));
        } else {
          // The gate, not the index: a Quran notification with no ayah of its
          // own reopens the page the user left off on.
          Modular.to.navigate(QuranRoutes.fullEntry());
        }
      case 'khatma':
        Modular.to.navigate(KhatmaRoutes.fullTracker());
      default:
        // Unknown payload — open home as a safe fallback.
        Modular.to.navigate(RoutesNames.homeBase);
    }
  }
}
