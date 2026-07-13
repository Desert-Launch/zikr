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

  List<MLocalNotification> getAll() => _box.box.values.toList(growable: false);

  /// Every stored notification whose payload type matches [type] (e.g. all
  /// `azkar` entries).
  List<MLocalNotification> byType(String type) => _box.box.values
      .where((n) => n.payloadType == type)
      .toList(growable: false);

  Future<void> delete(int id) async => _box.box.delete(id);

  Future<void> deleteAll(Iterable<int> ids) async => _box.box.deleteAll(ids);

  Future<void> clear() async => _box.box.clear();
}
