import 'package:quran/core/services/notifications/notification_box/m_notification.dart';
import 'package:quran/core/utils/hive_box_base.dart';

/// Persisted store of every scheduled local notification, keyed by its OS
/// scheduler id. Opened in `main()` alongside the other boxes; the adapter is
/// registered via the Hive registrar.
class BoxNotifications extends HiveBoxBase<MLocalNotification> {
  BoxNotifications() : super('scheduled_notifications');
}
