import 'package:quran/core/data/models/m_app_settings.dart';
import 'package:quran/core/services/notifications/notification_window.dart';
import 'package:quran/core/utils/hive_box_base.dart';

/// Single-record box (key = 0) for global flags like `hasSeenOnboarding`.
class BoxAppSettings extends HiveBoxBase<MAppSettings> {
  BoxAppSettings() : super('app_settings');

  MAppSettings current() {
    final existing = box.get(0);
    if (existing != null) return existing;
    final fresh = MAppSettings();
    box.put(0, fresh);
    return fresh;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final r = current();
    r.hasSeenOnboarding = value;
    await r.save();
  }

  Future<void> setLanguageCode(String? code) async {
    final r = current();
    r.lastLanguageCode = code;
    await r.save();
  }

  Future<void> setHasGrantedLocation(bool value) async {
    final r = current();
    r.hasGrantedLocation = value;
    await r.save();
  }

  Future<void> setInitNotificationsScheduled(bool value) async {
    final r = current();
    r.initNotificationsScheduled = value;
    await r.save();
  }

  Future<void> setHourlyTasbihSeeded(bool value) async {
    final r = current();
    r.hourlyTasbihSeeded = value;
    await r.save();
  }

  /// The window the salawat reminder and hourly zekr fire in — and nothing
  /// else; see [MAppSettings.reminderWindowStartHour].
  NotificationWindow reminderWindow() {
    final r = current();
    return NotificationWindow(
      startHour: r.reminderWindowStartHour,
      endHour: r.reminderWindowEndHour,
    );
  }

  /// Hours are stored modulo 24 so a bad picker value can never produce a
  /// window that resolves to no hours at all.
  Future<void> setReminderWindow(NotificationWindow window) async {
    final r = current();
    r
      ..reminderWindowStartHour = window.startHour % 24
      ..reminderWindowEndHour = window.endHour % 24;
    await r.save();
  }

  Future<void> setSalawatIgnoreSilent(bool value) async {
    final r = current();
    r.salawatIgnoreSilent = value;
    await r.save();
  }

  Future<void> setSalawatPauseOnCall(bool value) async {
    final r = current();
    r.salawatPauseOnCall = value;
    await r.save();
  }
}
