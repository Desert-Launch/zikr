import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';

class UCDownloadAdhanVoice {
  UCDownloadAdhanVoice(this._repo);
  final RAdhan _repo;

  Future<Either<Failure, String>> call(
    String voiceId, {
    void Function(int received, int total)? onProgress,
  }) =>
      _repo.downloadVoice(voiceId, onProgress: onProgress);
}
