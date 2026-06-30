import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_bookmarks.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_playback_prefs.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reader_settings.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_settings.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_tajweed.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_font_loader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_audio_downloads.dart';
import 'package:quran/modules/quran/data/repos/r_impl_bookmarks.dart';
import 'package:quran/modules/quran/data/repos/r_impl_playback_prefs.dart';
import 'package:quran/modules/quran/data/repos/r_impl_quran.dart';
import 'package:quran/modules/quran/data/repos/r_impl_reader_settings.dart';
import 'package:quran/modules/quran/data/repos/r_impl_reciter.dart';
import 'package:quran/modules/quran/data/repos/r_impl_tajweed.dart';
import 'package:quran/modules/quran/data/sources/local/box_bookmarks.dart';
import 'package:quran/modules/quran/data/sources/local/box_last_read.dart';
import 'package:quran/modules/quran/data/sources/local/box_playback_prefs.dart';
import 'package:quran/modules/quran/data/sources/local/box_reader_settings.dart';
import 'package:quran/modules/quran/data/sources/local/box_reciter_pref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';
import 'package:quran/modules/quran/domain/repos/r_playback_prefs.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/repos/r_reader_settings.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';
import 'package:quran/modules/quran/domain/repos/r_tajweed.dart';
import 'package:quran/modules/quran/domain/services/download_notifier.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_reciter_downloads.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_surah_download.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_all_surahs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_ensure_ayah_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_all_surahs_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_juz_index.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_page_layout.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reader_theme.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciter_stats.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_tajweed_tokens.dart';
import 'package:quran/modules/quran/domain/usecases/uc_play_ayah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_play_range.dart';
import 'package:quran/modules/quran/domain/usecases/uc_resolve_audio_url.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_bookmark.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_last_read.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_active_reciter.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_mode.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_font_scale.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_reader_theme.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter_surahs.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/screens/sn_bookmarks.dart';
import 'package:quran/modules/quran/presentation/screens/sn_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/screens/sn_quran_search.dart';
import 'package:quran/modules/quran/presentation/screens/sn_quran_settings.dart';
import 'package:quran/modules/quran/presentation/screens/sn_reciter_downloads.dart';
import 'package:quran/modules/quran/presentation/screens/sn_reciter_picker.dart';
import 'package:quran/modules/quran/presentation/screens/sn_reciter_surahs.dart';
import 'package:quran/modules/quran/presentation/screens/sn_surah_list.dart';
import 'package:quran/modules/quran/presentation/services/quran_download_notifier.dart';

class QuranModule extends Module {
  @override
  void binds(Injector i) {
    // Hive box wrappers — singletons since they manage open boxes.
    i.addSingleton<BoxBookmarks>(BoxBookmarks.new);
    i.addSingleton<BoxLastRead>(BoxLastRead.new);
    i.addSingleton<BoxReciterPref>(BoxReciterPref.new);
    i.addSingleton<BoxReaderSettings>(BoxReaderSettings.new);
    i.addSingleton<BoxPlaybackPrefs>(BoxPlaybackPrefs.new);

    // Local data sources
    i.addSingleton<DSLocalQuran>(DSLocalQuran.new);
    i.addSingleton<DSLocalBookmarks>(() => DSLocalBookmarks(i.get<BoxBookmarks>(), i.get<BoxLastRead>()));
    i.addSingleton<DSLocalSettings>(() => DSLocalSettings(i.get<BoxReciterPref>()));
    i.addSingleton<DSLocalReaderSettings>(() => DSLocalReaderSettings(i.get<BoxReaderSettings>()));
    i.addSingleton<DSLocalPlaybackPrefs>(() => DSLocalPlaybackPrefs(i.get<BoxPlaybackPrefs>()));
    i.addSingleton<DSLocalAudioFiles>(DSLocalAudioFiles.new);
    i.addSingleton<DSQpcFontLoader>(DSQpcFontLoader.new);
    i.addSingleton<DSLocalTajweed>(DSLocalTajweed.new);

    // Remote data sources
    i.addSingleton<DSRemoteAudio>(DSRemoteAudio.new);
    i.addSingleton<DSAudioDownloader>(DSAudioDownloader.new);

    // Repositories (interface → impl)
    i.addSingleton<RQuran>(() => RImplQuran(i.get<DSLocalQuran>()));
    i.addSingleton<RTajweed>(() => RImplTajweed(i.get<DSLocalTajweed>()));
    i.addSingleton<RReciter>(() => RImplReciter(i.get<DSLocalSettings>()));
    i.addSingleton<RAudio>(() => RImplAudio(i.get<DSLocalAudioFiles>(), i.get<DSRemoteAudio>(), i.get<RReciter>()));
    i.addSingleton<DownloadNotifier>(() => QuranDownloadNotifier(i.get<UCGetSurahList>()));
    i.addSingleton<RAudioDownloads>(
      () => RImplAudioDownloads(
        files: i.get<DSLocalAudioFiles>(),
        remote: i.get<DSRemoteAudio>(),
        downloader: i.get<DSAudioDownloader>(),
        reciter: i.get<RReciter>(),
        notifier: i.get<DownloadNotifier>(),
      ),
    );
    i.addSingleton<RBookmarks>(() => RImplBookmarks(i.get<DSLocalBookmarks>()));
    i.addSingleton<RReaderSettings>(() => RImplReaderSettings(i.get<DSLocalReaderSettings>()));
    i.addSingleton<RPlaybackPrefs>(() => RImplPlaybackPrefs(i.get<DSLocalPlaybackPrefs>()));

    // Use cases (factory)
    i.add<UCGetSurahList>(() => UCGetSurahList(i.get<RQuran>()));
    i.add<UCGetJuzIndex>(() => UCGetJuzIndex(i.get<RQuran>()));
    i.add<UCGetPageLayout>(() => UCGetPageLayout(i.get<RQuran>()));
    i.add<UCGetTajweedTokens>(() => UCGetTajweedTokens(i.get<RTajweed>()));
    i.add<UCSearchQuran>(() => UCSearchQuran(i.get<RQuran>()));
    i.add<UCResolveAudioUrl>(() => UCResolveAudioUrl(i.get<RAudio>()));
    i.add<UCPlayAyah>(UCPlayAyah.new);
    i.add<UCPlayRange>(UCPlayRange.new);
    i.add<UCEnsureAyahDownloaded>(() => UCEnsureAyahDownloaded(i.get<RAudioDownloads>()));
    i.add<UCDownloadSurah>(() => UCDownloadSurah(i.get<RAudioDownloads>()));
    i.add<UCDownloadAllSurahs>(() => UCDownloadAllSurahs(i.get<RAudioDownloads>()));
    i.add<UCGetSurahStatus>(() => UCGetSurahStatus(i.get<RAudioDownloads>()));
    i.add<UCGetAllSurahsStatus>(() => UCGetAllSurahsStatus(i.get<RAudioDownloads>()));
    i.add<UCGetReciterStats>(() => UCGetReciterStats(i.get<RAudioDownloads>()));
    i.add<UCDeleteSurahDownload>(() => UCDeleteSurahDownload(i.get<RAudioDownloads>()));
    i.add<UCDeleteReciterDownloads>(() => UCDeleteReciterDownloads(i.get<RAudioDownloads>()));
    i.add<UCSaveBookmark>(() => UCSaveBookmark(i.get<RBookmarks>()));
    i.add<UCGetBookmarks>(() => UCGetBookmarks(i.get<RBookmarks>()));
    i.add<UCSaveLastRead>(() => UCSaveLastRead(i.get<RBookmarks>()));
    i.add<UCGetReciters>(() => UCGetReciters(i.get<RReciter>()));
    i.add<UCSetActiveReciter>(() => UCSetActiveReciter(i.get<RReciter>()));
    i.add<UCGetFontMode>(() => UCGetFontMode(i.get<RReaderSettings>()));
    i.add<UCSetFontMode>(() => UCSetFontMode(i.get<RReaderSettings>()));
    i.add<UCGetReaderTheme>(() => UCGetReaderTheme(i.get<RReaderSettings>()));
    i.add<UCSetReaderTheme>(() => UCSetReaderTheme(i.get<RReaderSettings>()));
    i.add<UCGetFontScale>(() => UCGetFontScale(i.get<RReaderSettings>()));
    i.add<UCSetFontScale>(() => UCSetFontScale(i.get<RReaderSettings>()));
    i.add<UCGetPlaybackPrefs>(() => UCGetPlaybackPrefs(i.get<RPlaybackPrefs>()));
    i.add<UCSavePlaybackPrefs>(() => UCSavePlaybackPrefs(i.get<RPlaybackPrefs>()));

    // App-wide cubits (singletons survive navigation).
    i.addSingleton<CBAudioPlayer>(
      () => CBAudioPlayer(
        quran: i.get<RQuran>(),
        reciters: i.get<UCGetReciters>(),
        ensure: i.get<UCEnsureAyahDownloaded>(),
        getPrefs: i.get<UCGetPlaybackPrefs>(),
        savePrefs: i.get<UCSavePlaybackPrefs>(),
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
    // Reader display settings (font mode) — shared by the reader + settings
    // screen so a mode change re-renders an open reader instantly.
    i.addSingleton<CBReaderSettings>(
      () => CBReaderSettings(
        i.get<UCGetFontMode>(),
        i.get<UCSetFontMode>(),
        i.get<UCGetReaderTheme>(),
        i.get<UCSetReaderTheme>(),
        i.get<UCGetFontScale>(),
        i.get<UCSetFontScale>(),
      ),
    );

    // Per-screen cubits (factory).
    i.add<CBSurahList>(
      () => CBSurahList(
        i.get<UCGetSurahList>(),
        i.get<UCSaveLastRead>(),
        i.get<UCGetBookmarks>(),
        i.get<UCGetJuzIndex>(),
      ),
    );
    i.add<CBMushafReader>(
      () => CBMushafReader(
        i.get<UCGetPageLayout>(),
        i.get<UCSaveLastRead>(),
        i.get<DSQpcFontLoader>(),
        i.get<DSLocalQuran>(),
        i.get<RBookmarks>(),
        i.get<CBReaderSettings>(),
      ),
    );
    i.add<CBBookmarks>(() => CBBookmarks(i.get<UCGetBookmarks>(), i.get<UCSaveBookmark>()));
    i.add<CBQuranSearch>(() => CBQuranSearch(i.get<UCSearchQuran>()));
    i.add<CBReciterDownloads>(
      () => CBReciterDownloads(reciters: i.get<UCGetReciters>(), stats: i.get<UCGetReciterStats>()),
    );
    i.add<CBReciterSurahs>(
      () => CBReciterSurahs(
        surahs: i.get<UCGetSurahList>(),
        allStatus: i.get<UCGetAllSurahsStatus>(),
        surahStatus: i.get<UCGetSurahStatus>(),
        download: i.get<UCDownloadSurah>(),
        downloadAll: i.get<UCDownloadAllSurahs>(),
        deleteSurah: i.get<UCDeleteSurahDownload>(),
        stats: i.get<UCGetReciterStats>(),
        repo: i.get<RAudioDownloads>(),
      ),
    );
  }

  /// Eagerly opens the Hive boxes the module needs. Call from a screen `initState`
  /// or just rely on lazy `.init()` inside the data-sources.
  static Future<void> ensureBoxesOpen() async {
    await Modular.get<BoxBookmarks>().init();
    await Modular.get<BoxLastRead>().init();
    await Modular.get<BoxReciterPref>().init();
    await Modular.get<BoxReaderSettings>().init();
    await Modular.get<BoxPlaybackPrefs>().init();
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
    r.child(QuranRoutes.settings, child: (_) => const SNQuranSettings());
    r.child(QuranRoutes.reciterDownloads, child: (_) => const SNReciterDownloads());
    r.child(QuranRoutes.reciterSurahs, child: (_) => SNReciterSurahs(reciterId: r.args.queryParams['reciter'] ?? ''));
    r.child(QuranRoutes.bookmarks, child: (_) => const SNBookmarks());
    r.child(QuranRoutes.search, child: (_) => const SNQuranSearch());
  }
}
