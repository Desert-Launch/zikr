import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_download.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_delete_adhan_voice.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_download_adhan_voice.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_download.dart';

/// Drives voice-download progress for the picker. App-wide singleton so a
/// download keeps running while the user navigates away from the picker.
class CBAdhanDownload extends Cubit<SAdhanDownload> {
  CBAdhanDownload({
    required UCDownloadAdhanVoice download,
    required UCDeleteAdhanVoice delete,
    required BoxAdhanDownload downloads,
  })  : _download = download,
        _delete = delete,
        _downloads = downloads,
        super(const SAdhanDownload());

  final UCDownloadAdhanVoice _download;
  final UCDeleteAdhanVoice _delete;
  final BoxAdhanDownload _downloads;

  bool isDownloaded(String voiceId) => _downloads.isDownloaded(voiceId);

  Future<void> download(String voiceId) async {
    // Ignore a duplicate tap on an already-downloading voice.
    if (state.status == AdhanDownloadStatus.downloading &&
        state.voiceId == voiceId) {
      return;
    }
    emit(SAdhanDownload(
      status: AdhanDownloadStatus.downloading,
      voiceId: voiceId,
    ));

    final result = await _download(
      voiceId,
      onProgress: (received, total) {
        if (state.voiceId != voiceId) return;
        emit(state.copyWith(received: received, total: total));
      },
    );

    result.fold(
      (failure) => emit(SAdhanDownload(
        status: AdhanDownloadStatus.failure,
        voiceId: voiceId,
        error: failure.message,
      )),
      (_) => emit(SAdhanDownload(
        status: AdhanDownloadStatus.success,
        voiceId: voiceId,
      )),
    );
  }

  Future<void> remove(String voiceId) async {
    await _delete(voiceId);
    emit(const SAdhanDownload());
  }
}
