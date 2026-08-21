import 'package:quran/modules/azkar/domain/entities/e_azkar_audio_progress.dart';
import 'package:quran/modules/azkar/domain/repos/r_azkar_audio.dart';

/// Downloads a reader's pack, or one category of it. Idempotent: files already
/// on disk are skipped and a partial file resumes where it stopped.
class UCDownloadAzkarPack {
  UCDownloadAzkarPack(this._repo);
  final RAzkarAudio _repo;

  Stream<AzkarPackProgress> call(String readerId, {String? categoryId}) =>
      _repo.download(readerId, categoryId: categoryId);

  void cancel(String readerId) => _repo.cancel(readerId);

  bool isDownloading(String readerId) => _repo.isDownloading(readerId);

  AzkarPackProgress? activeProgress(String readerId) =>
      _repo.activeProgress(readerId);
}
