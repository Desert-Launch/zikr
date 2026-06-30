import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/adhan/presentation/cubits/cb_adhan_player.dart';

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
        // Trigger adhan playback for the named prayer (fire-and-forget), then
        // surface the prayer-times screen so the user sees what's playing.
        final prayer = payload.data['prayer']?.toString();
        if (prayer != null) {
          Modular.get<CBAdhanPlayer>().playForPrayer(prayer);
        }
        Modular.to.navigate(RoutesNames.prayerBase);
      case 'azkar':
        Modular.to.navigate(RoutesNames.azkarBase);
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
          Modular.to.navigate(RoutesNames.quranBase);
        }
      case 'khatma':
        Modular.to.navigate(KhatmaRoutes.fullTracker());
      default:
        // Unknown payload — open home as a safe fallback.
        Modular.to.navigate(RoutesNames.homeBase);
    }
  }
}
