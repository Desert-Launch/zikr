import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/quran/data/sources/local/box_tafsir.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_book.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

/// Fetches [TafsirCatalog.defaultBook] — التفسير الميسّر — once, so tafsir
/// works the first time a reader taps it on a fresh install instead of sending
/// them to the library to download something before they can read anything.
///
/// Entirely best-effort. The seed marker is written only after a successful
/// fetch, so a first launch spent offline retries on the next cold start; once
/// the marker is set the seed never runs again, which is what keeps a book the
/// reader deleted on purpose from reappearing.
class TafsirBootstrap {
  TafsirBootstrap({required RTafsir repo, required BoxTafsir box})
      : _repo = repo,
        _box = box;

  final RTafsir _repo;
  final BoxTafsir _box;

  Future<void> run() async {
    try {
      // The Quran route module is not mounted this early, so nothing has opened
      // the box yet. `init()` is a no-op when it already is.
      await _box.init();

      final res = await _repo.seedDefaultBook();
      res.fold(
        (failure) => AppLogger.warning(
          'Default tafsir not seeded (${failure.message}) — retrying next launch',
          tag: 'TafsirBootstrap',
        ),
        (downloaded) {
          if (downloaded) {
            AppLogger.info(
              '${TafsirCatalog.defaultBook.name} ready',
              tag: 'TafsirBootstrap',
            );
          }
        },
      );
    } catch (e, st) {
      AppLogger.error(
        'Tafsir bootstrap',
        error: e,
        stackTrace: st,
        tag: 'TafsirBootstrap',
      );
    }
  }
}
