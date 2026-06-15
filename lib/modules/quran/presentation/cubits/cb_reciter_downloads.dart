import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/entities/e_download_progress.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciter_stats.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter_downloads.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// Drives the reciter-list screen of the download manager. Loads reciters from
/// the catalogue, then fills in each reciter's disk stats (completed surahs +
/// bytes) in the background.
class CBReciterDownloads extends Cubit<SReciterDownloads> {
  CBReciterDownloads({
    required UCGetReciters reciters,
    required UCGetReciterStats stats,
  }) : _reciters = reciters,
       _stats = stats,
       super(const SReciterDownloads());

  final UCGetReciters _reciters;
  final UCGetReciterStats _stats;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    final res = await _reciters();
    final list = res.fold<List<MReciter>>((_) => const [], (l) => l);
    if (isClosed) return;
    res.fold(
      (f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)),
      (_) => emit(state.copyWith(status: LoadStatus.success, reciters: list)),
    );
    await _loadStats(list);
  }

  /// Re-scans disk stats (e.g. after returning from the surah screen).
  Future<void> refresh() async {
    if (state.reciters.isEmpty) {
      await load();
      return;
    }
    await _loadStats(state.reciters);
  }

  Future<void> _loadStats(List<MReciter> list) async {
    final map = <String, ReciterStats>{};
    for (final r in list) {
      final res = await _stats(r.id);
      if (isClosed) return;
      res.fold((_) {}, (s) => map[r.id] = s);
    }
    if (!isClosed) emit(state.copyWith(stats: Map.of(map)));
  }
}
