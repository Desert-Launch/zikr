import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_playback_prefs.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reciters.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_settings.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_audio_downloader.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_audio.dart';
import 'package:quran/modules/quran/data/repos/r_impl_audio_downloads.dart';
import 'package:quran/modules/quran/data/repos/r_impl_playback_prefs.dart';
import 'package:quran/modules/quran/data/repos/r_impl_quran.dart';
import 'package:quran/modules/quran/data/repos/r_impl_reciter.dart';
import 'package:quran/modules/quran/data/sources/local/box_playback_prefs.dart';
import 'package:quran/modules/quran/data/sources/local/box_reciter_pref.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';
import 'package:quran/modules/quran/domain/repos/r_playback_prefs.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';
import 'package:quran/modules/quran/domain/services/download_notifier.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_ensure_ayah_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_all_surahs_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_resolve_ayah_source.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_playback_prefs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_set_active_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/services/quran_download_notifier.dart';

/// The Qur'an audio graph — the recitation player, the reciter choice, and the
/// downloads and playback preferences under them — shared app-wide.
///
/// Imported by both [AppModule] and `QuranModule`. Modular builds an imported
/// module's binds once and hands every importer the same instances, so the
/// reader, the downloads screens and the car library all drive one player and
/// one download manager. Living in `QuranModule` alone, all of this was torn
/// down whenever the last Qur'an route was popped — and could not be reached
/// at all by a car asking to play a surah while the app sat on Home, or had no
/// screen open at all.
///
/// Lazy: nothing here is built until something first asks for it.
class QuranAudioModule extends Module {
  @override
  void exportedBinds(Injector i) {
    // Hive box wrappers (boxes are opened in main()).
    i.addLazySingleton<BoxReciterPref>(BoxReciterPref.new);
    i.addLazySingleton<BoxPlaybackPrefs>(BoxPlaybackPrefs.new);

    // Data sources
    i.addLazySingleton<DSLocalQuran>(DSLocalQuran.new);
    i.addLazySingleton<DSLocalSettings>(
      () => DSLocalSettings(i.get<BoxReciterPref>()),
    );
    i.addLazySingleton<DSLocalReciters>(DSLocalReciters.new);
    i.addLazySingleton<DSLocalPlaybackPrefs>(
      () => DSLocalPlaybackPrefs(i.get<BoxPlaybackPrefs>()),
    );
    i.addLazySingleton<DSLocalAudioFiles>(DSLocalAudioFiles.new);
    i.addLazySingleton<DSRemoteAudio>(DSRemoteAudio.new);
    i.addLazySingleton<DSAudioDownloader>(DSAudioDownloader.new);

    // Repositories (interface → impl)
    i.addLazySingleton<RQuran>(() => RImplQuran(i.get<DSLocalQuran>()));
    i.addLazySingleton<RReciter>(
      () => RImplReciter(i.get<DSLocalSettings>(), i.get<DSLocalReciters>()),
    );
    i.addLazySingleton<RAudio>(
      () => RImplAudio(
        i.get<DSLocalAudioFiles>(),
        i.get<DSRemoteAudio>(),
        i.get<RReciter>(),
      ),
    );
    i.addLazySingleton<DownloadNotifier>(
      () => QuranDownloadNotifier(i.get<UCGetSurahList>()),
    );
    i.addLazySingleton<RAudioDownloads>(
      () => RImplAudioDownloads(
        files: i.get<DSLocalAudioFiles>(),
        remote: i.get<DSRemoteAudio>(),
        downloader: i.get<DSAudioDownloader>(),
        reciter: i.get<RReciter>(),
        notifier: i.get<DownloadNotifier>(),
      ),
    );
    i.addLazySingleton<RPlaybackPrefs>(
      () => RImplPlaybackPrefs(i.get<DSLocalPlaybackPrefs>()),
    );

    // Use cases (factory)
    i.add<UCGetSurahList>(() => UCGetSurahList(i.get<RQuran>()));
    i.add<UCGetReciters>(() => UCGetReciters(i.get<RReciter>()));
    i.add<UCSetActiveReciter>(() => UCSetActiveReciter(i.get<RReciter>()));
    i.add<UCEnsureAyahDownloaded>(
      () => UCEnsureAyahDownloaded(i.get<RAudioDownloads>()),
    );
    i.add<UCResolveAyahSource>(
      () => UCResolveAyahSource(i.get<RAudioDownloads>()),
    );
    i.add<UCDownloadSurah>(() => UCDownloadSurah(i.get<RAudioDownloads>()));
    i.add<UCGetSurahStatus>(() => UCGetSurahStatus(i.get<RAudioDownloads>()));
    i.add<UCGetAllSurahsStatus>(
      () => UCGetAllSurahsStatus(i.get<RAudioDownloads>()),
    );
    i.add<UCGetPlaybackPrefs>(
      () => UCGetPlaybackPrefs(i.get<RPlaybackPrefs>()),
    );
    i.add<UCSavePlaybackPrefs>(
      () => UCSavePlaybackPrefs(i.get<RPlaybackPrefs>()),
    );

    // App-wide cubits
    i.addLazySingleton<CBAudioPlayer>(
      () => CBAudioPlayer(
        quran: i.get<RQuran>(),
        reciters: i.get<UCGetReciters>(),
        ensure: i.get<UCEnsureAyahDownloaded>(),
        resolve: i.get<UCResolveAyahSource>(),
        surahStatus: i.get<UCGetSurahStatus>(),
        downloadSurah: i.get<UCDownloadSurah>(),
        getPrefs: i.get<UCGetPlaybackPrefs>(),
        savePrefs: i.get<UCSavePlaybackPrefs>(),
      ),
    );
    i.addLazySingleton<CBReciter>(
      () => CBReciter(
        getReciters: i.get<UCGetReciters>(),
        setActive: i.get<UCSetActiveReciter>(),
        remote: i.get<DSRemoteAudio>(),
        audioPlayer: i.get<CBAudioPlayer>(),
      ),
    );
  }
}
