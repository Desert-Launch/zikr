import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/adhan/domain/repos/r_adhan.dart';

class UCDeleteAdhanVoice {
  UCDeleteAdhanVoice(this._repo);
  final RAdhan _repo;

  Future<Either<Failure, Unit>> call(String voiceId) =>
      _repo.deleteDownloadedVoice(voiceId);
}
