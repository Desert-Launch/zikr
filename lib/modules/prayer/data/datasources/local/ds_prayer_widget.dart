import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_widget_snapshot.dart';

/// The one place the app touches the `home_widget` plugin.
///
/// It is a thin sink: hand it a snapshot and it lands in the store the native
/// widgets read (SharedPreferences on Android, the App Group `UserDefaults`
/// on iOS) and the widgets are asked to redraw. Nothing here decides *what*
/// to publish — that is [PrayerWidgetPublisher]'s job.
///
/// Every call is best-effort. A missing plugin (a test, an isolate without
/// the channel) or a platform error is logged and swallowed: the widget is a
/// mirror of the prayer screen, and a mirror must never take the screen down.
class DSPrayerWidget {
  DSPrayerWidget();

  /// Shared container the iOS app and its widget extension both read. Must
  /// match `ios/Runner/Runner.entitlements` and
  /// `ios/PrayerWidget/PrayerWidget.entitlements`.
  static const String appGroupId = 'group.com.zikr.mapp';

  /// Fully-qualified `AppWidgetProvider` class on Android. Qualified because
  /// it lives in a sub-package; the plugin's default would look for it next
  /// to `MainActivity`.
  static const String androidProvider = 'com.zikr.mapp.widget.PrayerWidgetProvider';

  /// The `kind` the iOS widget declares.
  static const String iosKind = 'PrayerWidget';

  static const String _tag = 'DSPrayerWidget';

  /// Points the plugin at the App Group. iOS only — Android ignores it.
  Future<void> init() async {
    if (!Platform.isIOS) return;
    await _guard('init', () => HomeWidget.setAppGroupId(appGroupId));
  }

  /// Digest of the last snapshot written, or null when nothing was.
  Future<String?> readHash() =>
      _guard('readHash', () => HomeWidget.getWidgetData<String>(MPrayerWidgetSnapshot.hashKey));

  /// Persists [snapshot] and its digest, then asks both widgets to redraw.
  Future<void> write(MPrayerWidgetSnapshot snapshot) async {
    final stored = await _guard(
      'save',
      () => HomeWidget.saveWidgetData<String>(MPrayerWidgetSnapshot.storageKey, snapshot.encode()),
    );
    if (stored != true) return;
    await _guard(
      'saveHash',
      () => HomeWidget.saveWidgetData<String>(MPrayerWidgetSnapshot.hashKey, snapshot.contentHash),
    );
    await refresh();
  }

  /// Asks the launcher to place the widget (Android 8+, launchers that
  /// support pinning). False when it cannot — iOS, or an older launcher —
  /// in which case the caller tells the user how to add it by hand.
  Future<bool> requestPin() async {
    if (!Platform.isAndroid) return false;
    final supported = await _guard('pinSupported', HomeWidget.isRequestPinWidgetSupported) ?? false;
    if (!supported) return false;
    await _guard(
      'requestPin',
      () => HomeWidget.requestPinWidget(qualifiedAndroidName: androidProvider),
    );
    return true;
  }

  /// Redraws the widgets from whatever is stored.
  Future<void> refresh() => _guard(
    'update',
    () => HomeWidget.updateWidget(
      qualifiedAndroidName: androidProvider,
      iOSName: iosKind,
    ),
  );

  Future<T?> _guard<T>(String step, Future<T?> Function() run) async {
    try {
      return await run();
    } on MissingPluginException {
      // No channel on this isolate (tests, a headless engine without the
      // plugin registered). The widget keeps whatever it last had.
      return null;
    } on PlatformException catch (e) {
      // "-3" on Android means the provider class was not found — the widget
      // is misregistered, which a rebuild fixes and a log line should name.
      AppLogger.warning('Widget $step failed: ${e.code} ${e.message ?? ''}', tag: _tag);
      return null;
    } catch (e, st) {
      AppLogger.error('Widget $step failed', error: e, stackTrace: st, tag: _tag);
      return null;
    }
  }
}
