import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_widget.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_widget_snapshot.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';

/// Mirrors the resolved prayer schedule onto the home-screen widgets.
///
/// Called from wherever a schedule is resolved — the prayer cubit on screen,
/// and the adhan scheduler on boot and from the weekly background isolate —
/// so the widget is kept valid by the same paths that keep the adhan ringing,
/// including the ones that run when the app is never opened.
///
/// It publishes a window of days rather than "the next prayer": the widgets
/// cannot run Dart, so they must be able to roll from one prayer to the next,
/// and from tonight's Isha into tomorrow's Fajr, entirely on their own. See
/// [MPrayerWidgetSnapshot] for the shape.
///
/// A snapshot whose content matches the last one written is not written
/// again. iOS budgets timeline reloads per day, and every app open resolves
/// the schedule at least once; without this the budget would go on no-ops.
class PrayerWidgetPublisher {
  PrayerWidgetPublisher({required DSPrayerWidget widget}) : _widget = widget;

  final DSPrayerWidget _widget;

  static const String _tag = 'PrayerWidget';

  EPrayerSchedule? _last;
  bool _running = false;
  EPrayerSchedule? _pending;

  /// Renders [schedule] for the current language and hands it to the widgets.
  ///
  /// Concurrent calls are coalesced: the schedule that arrives while one is
  /// being written is published right after it, and only the newest one.
  Future<void> publish(EPrayerSchedule schedule) async {
    _last = schedule;
    if (_running) {
      _pending = schedule;
      return;
    }
    _running = true;
    try {
      await _write(schedule);
      while (_pending != null) {
        final next = _pending;
        _pending = null;
        if (next != null) await _write(next);
      }
    } finally {
      _running = false;
    }
  }

  /// Re-renders the last schedule in the current language.
  ///
  /// The widget carries its own strings, so a language switch has to push a
  /// new snapshot even though no timing changed.
  Future<void> republish() async {
    final last = _last;
    if (last == null) return;
    await publish(last);
  }

  Future<void> _write(EPrayerSchedule schedule) async {
    if (schedule.isEmpty) return;
    try {
      final lang = LocalizeAndTranslate.getLanguageCode();
      final snapshot = MPrayerWidgetSnapshot.fromSchedule(
        schedule,
        labels: _labels(schedule.cityName),
        lang: lang,
      );
      if (snapshot.days.isEmpty) return;

      final previous = await _widget.readHash();
      if (previous == snapshot.contentHash) {
        AppLogger.debug('Widget snapshot unchanged — not rewritten', tag: _tag);
        return;
      }

      await _widget.write(snapshot);
      AppLogger.info(
        'Widget snapshot published · ${snapshot.days.length} days · $lang · '
        '${schedule.timezone}',
        tag: _tag,
      );
    } catch (e, st) {
      // A widget that is behind is a cosmetic problem; a prayer screen that
      // fails to load because of it would not be.
      AppLogger.error('Widget publish failed', error: e, stackTrace: st, tag: _tag);
    }
  }

  /// Everything the widget prints, in the current language. Reuses the home
  /// card's keys so the widget and the card read identically.
  MPrayerWidgetLabels _labels(String city) {
    final caption = StringBuffer('prayer_next_label'.tr());
    if (city.isNotEmpty) {
      caption
        ..write(' ')
        ..write('home_timing'.tr().replaceFirst('{{city}}', city));
    }
    return MPrayerWidgetLabels(
      caption: caption.toString(),
      nextName: 'home_next_prayer'.tr(),
      after: 'widget_after'.tr(),
      remainingHm: 'home_remaining_hm'.tr(),
      remaining1Hm: 'home_remaining_1hm'.tr(),
      remainingM: 'home_remaining_m'.tr(),
      tomorrow: 'home_prayer_tomorrow'.tr(),
      empty: 'widget_empty'.tr(),
      prayers: {
        for (final prayer in EPrayer.values) prayer: 'prayer_${prayer.key}'.tr(),
      },
    );
  }
}
