import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_delete_azkar_audio.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_download_azkar_pack.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_get_azkar_audio_stats.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_get_azkar_readers.dart';
import 'package:quran/modules/azkar/domain/usecases/uc_set_preferred_azkar_reader.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio_downloads.dart';

/// Drives the adhkar audio download manager.
///
/// App-wide singleton, so a pack keeps downloading while the user leaves the
/// screen — and so coming back shows the run still in flight rather than a
/// reset progress bar.
class CBAzkarAudioDownloads extends Cubit<SAzkarAudioDownloads> {
  CBAzkarAudioDownloads({
    required UCGetAzkarReaders readers,
    required UCGetAzkarAudioStats stats,
    required UCDownloadAzkarPack download,
    required UCDeleteAzkarAudio delete,
    required UCSetPreferredAzkarReader preferredReader,
  }) : _readers = readers,
       _stats = stats,
       _download = download,
       _delete = delete,
       _preferredReader = preferredReader,
       super(const SAzkarAudioDownloads());

  final UCGetAzkarReaders _readers;
  final UCGetAzkarAudioStats _stats;
  final UCDownloadAzkarPack _download;
  final UCDeleteAzkarAudio _delete;
  final UCSetPreferredAzkarReader _preferredReader;

  final Map<String, StreamSubscription<AzkarPackProgress>> _subs =
      <String, StreamSubscription<AzkarPackProgress>>{};

  static const String _tag = 'CBAzkarAudioDownloads';

  /// Repairs download records that disagree with the filesystem. Called once
  /// during app boot, before any screen reads a count.
  Future<void> reconcile() async {
    final result = await _stats.reconcile();
    result.fold(
      (failure) => AppLogger.warning(
        'Adhkar audio reconcile failed: ${failure.message}',
        tag: _tag,
      ),
      (repaired) {
        if (repaired > 0) {
          AppLogger.info('Adhkar audio: $repaired records repaired', tag: _tag);
        }
      },
    );
  }

  Future<void> load() async {
    emit(
      state.copyWith(status: AzkarDownloadsStatus.loading, clearError: true),
    );
    final result = await _readers();
    if (isClosed) return;
    final list = result.fold<List<MAzkarReader>>((_) => const [], (l) => l);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AzkarDownloadsStatus.error,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AzkarDownloadsStatus.ready,
          readers: list,
          preferredReaderId: _preferredReader.current,
        ),
      ),
    );
    await refresh();
  }

  /// Re-reads disk figures. Cheap enough to call on returning to the screen.
  Future<void> refresh() async {
    final statsResult = await _stats();
    if (isClosed) return;
    statsResult.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (map) => emit(state.copyWith(stats: Map.of(map), clearError: true)),
    );

    final storageResult = await _stats.storage();
    if (isClosed) return;
    storageResult.fold((_) {}, (usage) => emit(state.copyWith(storage: usage)));
  }

  Future<void> loadCategories(String readerId) async {
    final result = await _stats.categories(readerId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (list) => emit(
        state.copyWith(
          categories: <String, List<AzkarCategoryAudioInfo>>{
            ...state.categories,
            readerId: list,
          },
        ),
      ),
    );
  }

  /// Starts (or joins) a download run for a whole reader, or one category.
  void start(String readerId, {String? categoryId}) {
    // A second tap must not open a second subscription onto the same run.
    if (_subs.containsKey(readerId)) return;
    _subs[readerId] = _download(readerId, categoryId: categoryId).listen(
      (progress) {
        if (isClosed) return;
        emit(
          state.copyWith(
            progress: <String, AzkarPackProgress>{
              ...state.progress,
              readerId: progress,
            },
          ),
        );
      },
      onError: (Object e) {
        AppLogger.warning('Adhkar pack download error: $e', tag: _tag);
        if (isClosed) return;
        emit(state.copyWith(error: e.toString()));
      },
      onDone: () async {
        await _subs.remove(readerId)?.cancel();
        if (isClosed) return;
        await refresh();
        await loadCategories(readerId);
      },
      cancelOnError: false,
    );
  }

  void cancel(String readerId) {
    _download.cancel(readerId);
  }

  Future<void> deleteReader(String readerId) async {
    final result = await _delete.reader(readerId);
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(state.copyWith(error: failure.message)),
      (_) async {
        final progress = Map<String, AzkarPackProgress>.from(state.progress)
          ..remove(readerId);
        emit(state.copyWith(progress: progress, clearError: true));
        await refresh();
        await loadCategories(readerId);
      },
    );
  }

  Future<void> deleteCategory(String readerId, String categoryId) async {
    final result = await _delete.category(readerId, categoryId);
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(state.copyWith(error: failure.message)),
      (_) async {
        await refresh();
        await loadCategories(readerId);
      },
    );
  }

  Future<void> deleteAll() async {
    final result = await _delete.all();
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(state.copyWith(error: failure.message)),
      (_) async {
        emit(
          state.copyWith(
            progress: const <String, AzkarPackProgress>{},
            categories: const <String, List<AzkarCategoryAudioInfo>>{},
            clearError: true,
          ),
        );
        await refresh();
      },
    );
  }

  Future<void> setPreferredReader(String? readerId) async {
    final result = await _preferredReader(readerId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(
        readerId == null
            ? state.copyWith(clearPreferred: true, clearError: true)
            : state.copyWith(preferredReaderId: readerId, clearError: true),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    _subs.clear();
    return super.close();
  }
}
