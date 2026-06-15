import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/entities/e_surah_download_status.dart';
import 'package:quran/modules/quran/domain/repos/r_audio_downloads.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_surah_download.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_all_surahs.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_all_surahs_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciter_stats.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_status.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter_surahs.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// Drives the per-reciter surah download screen. Holds the live progress of any
/// in-flight surah download (its own, or one started by the audio player in the
/// background) and keeps disk-truth status in sync as downloads complete.
class CBReciterSurahs extends Cubit<SReciterSurahs> {
  CBReciterSurahs({
    required UCGetSurahList surahs,
    required UCGetAllSurahsStatus allStatus,
    required UCGetSurahStatus surahStatus,
    required UCDownloadSurah download,
    required UCDownloadAllSurahs downloadAll,
    required UCDeleteSurahDownload deleteSurah,
    required UCGetReciterStats stats,
    required RAudioDownloads repo,
  }) : _surahs = surahs,
       _allStatus = allStatus,
       _surahStatus = surahStatus,
       _download = download,
       _downloadAll = downloadAll,
       _deleteSurah = deleteSurah,
       _stats = stats,
       _repo = repo,
       super(const SReciterSurahs());

  final UCGetSurahList _surahs;
  final UCGetAllSurahsStatus _allStatus;
  final UCGetSurahStatus _surahStatus;
  final UCDownloadSurah _download;
  final UCDownloadAllSurahs _downloadAll;
  final UCDeleteSurahDownload _deleteSurah;
  final UCGetReciterStats _stats;
  final RAudioDownloads _repo;

  final Map<int, StreamSubscription<SurahDownloadProgress>> _subs = {};
  StreamSubscription<AllSurahsDownloadProgress>? _allSub;

  Future<void> load(String reciterId) async {
    emit(state.copyWith(reciterId: reciterId, status: LoadStatus.loading, clearError: true));
    final sRes = await _surahs();
    if (isClosed) return;
    final list = sRes.fold<List<MSurah>>((_) => const [], (l) => l);
    final iRes = await _allStatus(reciterId);
    if (isClosed) return;
    final info = iRes.fold<Map<int, SurahDownloadInfo>>((_) => const {}, (m) => m);
    emit(state.copyWith(status: LoadStatus.success, surahs: list, infoBySurah: info));
    await _refreshStats();
    // Adopt any downloads already in flight (e.g. started by the audio player).
    for (final s in list) {
      if (_repo.isSurahDownloading(reciterId, s.number)) _subscribe(s.number);
    }
  }

  void downloadSurah(int surah) => _subscribe(surah);

  void _subscribe(int surah) {
    if (_subs.containsKey(surah)) return;
    final reciterId = state.reciterId;
    final seed = _repo.activeProgress(reciterId, surah);
    if (seed != null) _putProgress(surah, seed);
    _subs[surah] = _download(reciterId, surah).listen(
      (p) => _putProgress(surah, p),
      onError: (Object _) {},
      onDone: () => unawaited(_onSurahDone(surah)),
    );
  }

  void _putProgress(int surah, SurahDownloadProgress p) {
    if (isClosed) return;
    emit(state.copyWith(progressBySurah: {...state.progressBySurah, surah: p}));
  }

  Future<void> _onSurahDone(int surah) async {
    await _subs.remove(surah)?.cancel();
    if (isClosed) return;
    emit(state.copyWith(progressBySurah: {...state.progressBySurah}..remove(surah)));
    await _refreshSurah(surah);
    await _refreshStats();
  }

  Future<void> downloadAll() async {
    if (state.isDownloadingAll) return;
    emit(state.copyWith(isDownloadingAll: true));
    _allSub = _downloadAll(state.reciterId).listen(
      _onAllProgress,
      onError: (Object _) {},
      onDone: () => unawaited(_onAllDone()),
    );
  }

  void _onAllProgress(AllSurahsDownloadProgress p) {
    if (isClosed) return;
    final surah = p.currentSurah;
    final prog = p.currentSurahProgress;
    if (prog.isDone) {
      emit(state.copyWith(
        allCurrentSurah: surah,
        progressBySurah: {...state.progressBySurah}..remove(surah),
      ));
      unawaited(_refreshSurah(surah));
    } else {
      emit(state.copyWith(
        allCurrentSurah: surah,
        progressBySurah: {...state.progressBySurah, surah: prog},
      ));
    }
  }

  Future<void> _onAllDone() async {
    await _allSub?.cancel();
    _allSub = null;
    if (isClosed) return;
    emit(state.copyWith(isDownloadingAll: false, progressBySurah: const {}));
    await _reload();
  }

  Future<void> cancelAll() async {
    _repo.cancelAll();
    await _allSub?.cancel();
    _allSub = null;
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    _subs.clear();
    if (isClosed) return;
    emit(state.copyWith(isDownloadingAll: false, progressBySurah: const {}));
    await _reload();
  }

  Future<void> deleteSurah(int surah) async {
    await _deleteSurah(state.reciterId, surah);
    if (isClosed) return;
    await _refreshSurah(surah);
    await _refreshStats();
  }

  Future<void> _refreshSurah(int surah) async {
    final res = await _surahStatus(state.reciterId, surah);
    if (isClosed) return;
    res.fold((_) {}, (info) {
      emit(state.copyWith(infoBySurah: {...state.infoBySurah, surah: info}));
    });
  }

  Future<void> _refreshStats() async {
    final res = await _stats(state.reciterId);
    if (isClosed) return;
    res.fold((_) {}, (s) => emit(state.copyWith(stats: s)));
  }

  Future<void> _reload() async {
    final iRes = await _allStatus(state.reciterId);
    if (isClosed) return;
    iRes.fold((_) {}, (m) => emit(state.copyWith(infoBySurah: m)));
    await _refreshStats();
  }

  @override
  Future<void> close() async {
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    await _allSub?.cancel();
    return super.close();
  }
}
