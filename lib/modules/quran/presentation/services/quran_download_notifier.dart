import 'dart:async';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/quran/domain/services/download_notifier.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';

/// Drives a single ongoing OS notification that shows the surah currently
/// downloading and its progress. Resolves [NotificationsService] lazily via
/// Modular (it is a root/app-wide singleton) so this can live inside the Quran
/// module without a cross-module constructor dependency.
class QuranDownloadNotifier implements DownloadNotifier {
  QuranDownloadNotifier(this._surahs);

  final UCGetSurahList _surahs;

  /// Stable id so progress updates replace (not stack) the notification.
  static const int _notificationId = 7710;

  Map<int, String>? _names;
  bool _loadingNames = false;
  int _lastSurah = -1;
  int _lastPct = -1;

  Future<void> _ensureNames() async {
    if (_names != null || _loadingNames) return;
    _loadingNames = true;
    final res = await _surahs();
    _names = res.fold(
      (_) => <int, String>{},
      (list) => {for (final s in list) s.number: s.arabic},
    );
    _loadingNames = false;
  }

  @override
  void notifySurahProgress({
    required int surah,
    required int onDisk,
    required int total,
  }) {
    final pct = total <= 0 ? 0 : ((onDisk / total) * 100).floor();
    // Throttle: only re-post when the surah or whole-percent value changes.
    if (surah == _lastSurah && pct == _lastPct) return;
    _lastSurah = surah;
    _lastPct = pct;
    unawaited(_show(surah, onDisk, total));
  }

  Future<void> _show(int surah, int onDisk, int total) async {
    await _ensureNames();
    final name = _names?[surah] ?? 'سورة $surah';
    await Modular.get<NotificationsService>().showDownloadProgress(
      id: _notificationId,
      title: 'quran_download_notification_title'.tr(),
      body: '$name — $onDisk/$total',
      maxProgress: total,
      progress: onDisk,
    );
  }

  @override
  void notifyIdle() {
    _lastSurah = -1;
    _lastPct = -1;
    unawaited(Modular.get<NotificationsService>().cancel(_notificationId));
  }
}
