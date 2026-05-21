import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_cancel_download.dart';
import 'package:quran/modules/quran/domain/usecases/uc_delete_downloaded.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_juz.dart';
import 'package:quran/modules/quran/domain/usecases/uc_download_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_storage_summary.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/domain/repos/r_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class CBDownloads extends Cubit<SDownloads> {
  CBDownloads({
    required UCGetSurahList surahs,
    required UCGetReciters reciters,
    required UCDownloadSurah dSurah,
    required UCDownloadJuz dJuz,
    required UCCancelDownload cancel,
    required UCDeleteDownloaded delete,
    required UCGetStorageSummary storage,
    required RDownloads repo,
  })  : _surahs = surahs,
        _reciters = reciters,
        _dSurah = dSurah,
        _dJuz = dJuz,
        _cancel = cancel,
        _delete = delete,
        _storage = storage,
        _repo = repo,
        super(const SDownloads());

  final UCGetSurahList _surahs;
  final UCGetReciters _reciters;
  final UCDownloadSurah _dSurah;
  final UCDownloadJuz _dJuz;
  final UCCancelDownload _cancel;
  final UCDeleteDownloaded _delete;
  final UCGetStorageSummary _storage;
  final RDownloads _repo;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final surahsRes = await _surahs();
    final recitersRes = await _reciters();
    final activeRes = await _reciters.active();
    final tasksRes = await _repo.listTasks();
    final totalRes = await _storage();

    emit(state.copyWith(
      status: LoadStatus.success,
      surahs: surahsRes.fold((_) => const [], (l) => l),
      reciters: recitersRes.fold((_) => const [], (l) => l),
      activeReciterId: activeRes.fold((_) => state.activeReciterId, (r) => r.id),
      tasks: {
        for (final t in tasksRes.fold((_) => <dynamic>[], (l) => l)) (t.id as String): t,
      },
      totalBytes: totalRes.fold((_) => 0, (b) => b),
    ));
  }

  void setReciter(String id) => emit(state.copyWith(activeReciterId: id));
  void setGroupBy(DownloadGroupBy g) => emit(state.copyWith(groupBy: g));

  Future<void> downloadSurah(int surah) async {
    final reciterId = state.activeReciterId;
    if (reciterId == null) return;
    final res = await _dSurah(reciterId: reciterId, surah: surah);
    res.fold((f) => emit(state.copyWith(error: f.message)), (task) {
      emit(state.copyWith(tasks: {...state.tasks, task.id: task}));
    });
    await _refreshTotal();
  }

  Future<void> downloadJuz(int juz) async {
    final reciterId = state.activeReciterId;
    if (reciterId == null) return;
    final res = await _dJuz(reciterId: reciterId, juz: juz);
    res.fold((f) => emit(state.copyWith(error: f.message)), (task) {
      emit(state.copyWith(tasks: {...state.tasks, task.id: task}));
    });
    await _refreshTotal();
  }

  Future<void> cancelTask(String taskId) async {
    await _cancel(taskId);
    await load();
  }

  Future<void> deleteTask(String taskId) async {
    await _delete(taskId);
    await load();
  }

  Future<void> deleteAllForReciter(String reciterId) async {
    await _delete.deleteAllForReciter(reciterId);
    await load();
  }

  Future<void> _refreshTotal() async {
    final res = await _storage();
    emit(state.copyWith(totalBytes: res.fold((_) => state.totalBytes, (b) => b)));
  }
}
