import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';

abstract class RAdhan {
  /// The full voice catalog — remote (CDN) merged over the bundled list, or
  /// just the bundled list when the network is unavailable.
  Future<Either<Failure, List<MAdhan>>> fetchCatalog();

  /// Downloads the full adhan for [voiceId] to app storage, reporting
  /// progress. Returns the local file path on success.
  Future<Either<Failure, String>> downloadVoice(
    String voiceId, {
    void Function(int received, int total)? onProgress,
  });

  /// Removes a downloaded (non-bundled) voice file to free space.
  Future<Either<Failure, Unit>> deleteDownloadedVoice(String voiceId);
}
