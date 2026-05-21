import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_bookmarks.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_settings.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_bookmarks.dart';
import 'package:quran/modules/quran/data/repos/r_impl_downloads.dart';
import 'package:quran/modules/quran/data/repos/r_impl_quran.dart';
import 'package:quran/modules/quran/data/repos/r_impl_reciter.dart';
import 'package:quran/modules/quran/data/sources/local/box_bookmarks.dart';
import 'package:quran/modules/quran/data/sources/local/box_download_tasks.dart';
import 'package:quran/modules/quran/data/sources/local/box_last_read.dart';
import 'package:quran/modules/quran/data/sources/local/box_reciter_pref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';
import 'package:quran/modules/quran/domain/usecases/uc_cancel_download.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_juz.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_page_layout.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_storage_summary.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_play_ayah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_play_range.dart';
import 'package:quran/modules/quran/domain/usecases/uc_resolve_audio_url.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_bookmark.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_active_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/screens/sn_bookmarks.dart';
import 'package:quran/modules/quran/presentation/screens/sn_downloads.dart';
import 'package:quran/modules/quran/presentation/screens/sn_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/screens/sn_quran_search.dart';
import 'package:quran/modules/quran/presentation/screens/sn_reciter_picker.dart';
import 'package:quran/modules/quran/presentation/screens/sn_surah_list.dart';

class QuranModule extends Module {
  @override
  void binds(Injector i) {
    // Hive box wrappers — singletons since they manage open boxes.
    i.addSingleton<BoxBookmarks>(BoxBookmarks.new);
    i.addSingleton<BoxLastRead>(BoxLastRead.new);
    i.addSingleton<BoxReciterPref>(BoxReciterPref.new);
    i.addSingleton<BoxDownloadTasks>(BoxDownloadTasks.new);

    // Local data sources
    i.addSingleton<DSLocalQuran>(DSLocalQuran.new);
    i.addSingleton<DSLocalBookmarks>(
      () => DSLocalBookmarks(i.get<BoxBookmarks>(), i.get<BoxLastRead>()),
    );
    i.addSingleton<DSLocalSettings>(() => DSLocalSettings(i.get<BoxReciterPref>()));
    i.addSingleton<DSLocalAudioFiles>(DSLocalAudioFiles.new);
    i.addSingleton<DSQpcFontLoader>(DSQpcFontLoader.new);

    // Remote data sources
    i.addSingleton<DSRemoteAudio>(DSRemoteAudio.new);
    i.addSingleton<DSAudioDownloader>(DSAudioDownloader.new);

    // Repositories (interface → impl)
    i.addSingleton<RQuran>(() => RImplQuran(i.get<DSLocalQuran>()));
    i.addSingleton<RReciter>(() => RImplReciter(i.get<DSLocalSettings>()));
    i.addSingleton<RAudio>(
      () => RImplAudio(i.get<DSLocalAudioFiles>(), i.get<DSRemoteAudio>(), i.get<RReciter>()),
    );
    i.addSingleton<RBookmarks>(() => RImplBookmarks(i.get<DSLocalBookmarks>()));
    i.addSingleton<RDownloads>(
      () => RImplDownloads(
        tasksBox: i.get<BoxDownloadTasks>(),
        downloader: i.get<DSAudioDownloader>(),
        remote: i.get<DSRemoteAudio>(),
        files: i.get<DSLocalAudioFiles>(),
        quran: i.get<RQuran>(),
        reciter: i.get<RReciter>(),
      ),
    );

    // Use cases (factory)
    i.add<UCGetSurahList>(() => UCGetSurahList(i.get<RQuran>()));
    i.add<UCGetPageLayout>(() => UCGetPageLayout(i.get<RQuran>()));
    i.add<UCSearchQuran>(() => UCSearchQuran(i.get<RQuran>()));
    i.add<UCResolveAudioUrl>(() => UCResolveAudioUrl(i.get<RAudio>()));
    i.add<UCPlayAyah>(UCPlayAyah.new);
    i.add<UCPlayRange>(UCPlayRange.new);
    i.add<UCDownloadSurah>(() => UCDownloadSurah(i.get<RDownloads>()));
    i.add<UCDownloadJuz>(() => UCDownloadJuz(i.get<RDownloads>()));
    i.add<UCCancelDownload>(() => UCCancelDownload(i.get<RDownloads>()));
    i.add<UCDeleteDownloaded>(() => UCDeleteDownloaded(i.get<RDownloads>()));
    i.add<UCGetStorageSummary>(() => UCGetStorageSummary(i.get<RDownloads>()));
    i.add<UCSaveBookmark>(() => UCSaveBookmark(i.get<RBookmarks>()));
    i.add<UCGetBookmarks>(() => UCGetBookmarks(i.get<RBookmarks>()));
    i.add<UCSaveLastRead>(() => UCSaveLastRead(i.get<RBookmarks>()));
    i.add<UCGetReciters>(() => UCGetReciters(i.get<RReciter>()));
    i.add<UCSetActiveReciter>(() => UCSetActiveReciter(i.get<RReciter>()));

    // App-wide cubits (singletons survive navigation).
    i.addSingleton<CBAudioPlayer>(
      () => CBAudioPlayer(
        audio: i.get<RAudio>(),
        quran: i.get<RQuran>(),
        reciters: i.get<UCGetReciters>(),
      ),
    );
    i.addSingleton<CBReciter>(
      () => CBReciter(
        getReciters: i.get<UCGetReciters>(),
        setActive: i.get<UCSetActiveReciter>(),
        remote: i.get<DSRemoteAudio>(),
        audioPlayer: i.get<CBAudioPlayer>(),
      ),
    );
    i.addSingleton<CBDownloads>(
      () => CBDownloads(
        surahs: i.get<UCGetSurahList>(),
        reciters: i.get<UCGetReciters>(),
        dSurah: i.get<UCDownloadSurah>(),
        dJuz: i.get<UCDownloadJuz>(),
        cancel: i.get<UCCancelDownload>(),
        delete: i.get<UCDeleteDownloaded>(),
        storage: i.get<UCGetStorageSummary>(),
        repo: i.get<RDownloads>(),
      ),
    );

    // Per-screen cubits (factory).
    i.add<CBSurahList>(
      () => CBSurahList(i.get<UCGetSurahList>(), i.get<UCSaveLastRead>(), i.get<UCGetBookmarks>()),
    );
    i.add<CBMushafReader>(
      () => CBMushafReader(i.get<UCGetPageLayout>(), i.get<UCSaveLastRead>(), i.get<DSQpcFontLoader>()),
    );
    i.add<CBBookmarks>(
      () => CBBookmarks(i.get<UCGetBookmarks>(), i.get<UCSaveBookmark>()),
    );
  }

  /// Eagerly opens the Hive boxes the module needs. Call from a screen `initState`
  /// or just rely on lazy `.init()` inside the data-sources.
  static Future<void> ensureBoxesOpen() async {
    await Modular.get<BoxBookmarks>().init();
    await Modular.get<BoxLastRead>().init();
    await Modular.get<BoxReciterPref>().init();
    await Modular.get<BoxDownloadTasks>().init();
  }

  @override
  void routes(RouteManager r) {
    r.child(QuranRoutes.surahList, child: (_) => const SNSurahList());
    r.child(
      QuranRoutes.reader,
      child: (_) {
        final args = r.args;
        final params = args.queryParams;
        final page = int.tryParse(params['page'] ?? '');
        final surah = int.tryParse(params['surah'] ?? '');
        final ayah = int.tryParse(params['ayah'] ?? '');
        return SNMushafReader(
          initialPage: page,
          initialAyah: (surah != null && ayah != null) ? (surah: surah, ayah: ayah) : null,
        );
      },
    );
    r.child(QuranRoutes.reciterPicker, child: (_) => const SNReciterPicker());
    r.child(QuranRoutes.downloads, child: (_) => const SNDownloads());
    r.child(QuranRoutes.bookmarks, child: (_) => const SNBookmarks());
    r.child(QuranRoutes.search, child: (_) => const SNQuranSearch());
  }
}
