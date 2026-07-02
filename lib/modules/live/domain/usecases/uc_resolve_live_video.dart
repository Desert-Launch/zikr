import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/live/domain/repos/r_live.dart';

class UCResolveLiveVideo {
  UCResolveLiveVideo(this._repo);
  final RLive _repo;

  Future<Either<Failure, String>> call(String channelId) =>
      _repo.resolveLiveVideoId(channelId);
}
