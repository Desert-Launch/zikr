import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';

/// First-launch flow (Phase 1): seed the default voice + settings and try to
/// download the default full adhan. Gated by `MAdhanSettings.bootstrapped` so
/// it runs once. Entirely best-effort — the bundled clip keeps notifications
/// working even if every network step here fails.
class AdhanBootstrap {
  AdhanBootstrap({
    required RAdhan repo,
    required BoxAdhanSettings settings,
    required BoxAdhanPreference prefs,
    required DSLocalAdhan local,
    required String localeTag,
  })  : _repo = repo,
        _settings = settings,
        _prefs = prefs,
        _local = local,
        _localeTag = localeTag;

  final RAdhan _repo;
  final BoxAdhanSettings _settings;
  final BoxAdhanPreference _prefs;
  final DSLocalAdhan _local;
  final String _localeTag;

  Future<void> run() async {
    final s = _settings.current();
    if (s.bootstrapped) return;

    try {
      // 1. Seed the default voice if the user hasn't chosen one.
      if (_prefs.current().defaultAdhanId == null) {
        final defaultVoice = await _local.defaultForLocale(_localeTag);
        await _prefs.setDefault(defaultVoice.id);
      }

      // 2. Best-effort catalog fetch + default full download. Failures here
      //    are expected until a real CDN is wired — the bundled clip suffices.
      final catalog = await _repo.fetchCatalog();
      final defaultId = _prefs.current().defaultAdhanId;
      catalog.fold((_) {}, (voices) async {
        for (final v in voices) {
          if (v.id == defaultId && v.isDownloadable) {
            await _repo.downloadVoice(v.id);
            break;
          }
        }
      });
    } catch (e, st) {
      AppLogger.warning('Adhan bootstrap incomplete: $e', tag: 'AdhanBootstrap');
      AppLogger.error('Adhan bootstrap', error: e, stackTrace: st,
          tag: 'AdhanBootstrap');
    } finally {
      // Mark done regardless — we don't want to re-run network every cold start.
      final done = _settings.current()..bootstrapped = true;
      await _settings.save(done);
    }
  }
}
