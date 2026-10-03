import 'package:quran/core/services/notifications/notification_box/box_notifications.dart';
import 'package:quran/core/services/notifications/notification_box/m_notification.dart';

/// Thin persistence facade over [BoxNotifications]. Lets higher-level
/// schedulers store, read, and reconcile the notifications they've placed with
/// the OS without touching Hive directly.
class DSNotification {
  DSNotification(this._box);

  final BoxNotifications _box;

  /// Upserts [notification], keyed by its id.
  Future<void> put(MLocalNotification notification) async =>
      _box.box.put(notification.id, notification);

  MLocalNotification? get(int id) => _box.box.get(id);

  Future<void> delete(int id) async => _box.box.delete(id);

  Future<void> deleteAll(Iterable<int> ids) async => _box.box.deleteAll(ids);

  Future<void> clear() async => _box.box.clear();
}
