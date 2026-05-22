import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';

/// Schedules the hourly tasbih notifications (Decision 2). One per hour from
/// 08:00 to 22:00, silent + low importance — see [AppNotificationChannels.hourly].
///
/// Notification IDs reserved: 5000..5014 (one per active hour).
class DSHourlyTasbih {
  DSHourlyTasbih(this._notifications);

  final NotificationsService _notifications;

  static const _baseId = 5000;
  static const _activeHours = [
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
  ];

  /// Hourly phrases — cycled through with `hour % len`. Keeps notifications
  /// varied across the day instead of showing the same zekr every hour.
  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ',
  ];

  Future<void> enable() async {
    for (final hour in _activeHours) {
      final phrase = _phrases[hour % _phrases.length];
      await _notifications.scheduleDaily(
        id: _baseId + hour,
        hour: hour,
        minute: 0,
        title: 'تذكير الساعة',
        body: phrase,
        channel: AppNotificationChannels.hourly,
        payload: const NotificationPayload(type: 'hourly'),
      );
    }
  }

  Future<void> disable() async {
    for (final hour in _activeHours) {
      await _notifications.cancel(_baseId + hour);
    }
  }
}
