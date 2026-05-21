import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_audio_files.dart';
import 'package:quran/modules/quran/data/datasources/remote/ds_remote_audio.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/repos/r_audio.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';

class RImplAudio implements RAudio {
  RImplAudio(this._files, this._remote, this._reciter);
  final DSLocalAudioFiles _files;
  final DSRemoteAudio _remote;
  final RReciter _reciter;

  Future<MReciter?> _lookupReciter(String id) async {
    final eitherList = await _reciter.getReciters();
    return eitherList.fold<MReciter?>(
      (_) => null,
      (list) => list.firstWhere((r) => r.id == id,
          orElse: () => list.firstWhere((r) => r.isDefault, orElse: () => list.first)),
    );
  }

  /// Sequential ayah number in the Quran (1..6236) — used for AlQuran.cloud fallback.
  static int _sequentialAyahNumber(int surah, int ayah) {
    const surahLens = [
      7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
      112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,
      89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,
      12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,
      30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
    ];
    int total = 0;
    for (int i = 0; i < surah - 1; i++) {
      total += surahLens[i];
    }
    return total + ayah;
  }

  @override
  Future<bool> isDownloaded({
    required String reciterId,
    required int surah,
    required int ayah,
  }) {
    return _files.exists(reciterId, surah, ayah);
  }

  @override
  Future<Either<Failure, String>> resolveAyahAudio({
    required String reciterId,
    required int surah,
    required int ayah,
  }) async {
    try {
      if (await _files.exists(reciterId, surah, ayah)) {
        final path = await _files.pathFor(reciterId, surah, ayah);
        return Right('file://$path');
      }
      final reciter = await _lookupReciter(reciterId);
      if (reciter == null) {
        return Left(Failure.notFoundFailure(message: 'Reciter $reciterId not found'));
      }
      return Right(_remote.primaryUrl(folder: reciter.folder, surah: surah, ayah: ayah));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAudio.resolveAyahAudio', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> resolveRange({
    required String reciterId,
    required int fromSurah,
    required int fromAyah,
    required int toSurah,
    required int toAyah,
  }) async {
    try {
      final reciter = await _lookupReciter(reciterId);
      if (reciter == null) {
        return Left(Failure.notFoundFailure(message: 'Reciter $reciterId not found'));
      }
      final urls = <String>[];
      int s = fromSurah, a = fromAyah;
      while (s < toSurah || (s == toSurah && a <= toAyah)) {
        if (await _files.exists(reciterId, s, a)) {
          urls.add('file://${await _files.pathFor(reciterId, s, a)}');
        } else {
          urls.add(_remote.primaryUrl(folder: reciter.folder, surah: s, ayah: a));
        }
        a++;
        // Naïve surah-end detection: caller passes well-formed ranges in v1.
        if (s < toSurah && a > 286) {
          s++;
          a = 1;
        }
      }
      return Right(urls);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAudio.resolveRange', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  /// Generates the AlQuran.cloud fallback URL for a specific reciter/ayah,
  /// or null if no fallback exists.
  String? fallbackUrlFor(String reciterId, int surah, int ayah, {int bitrate = 128}) {
    return _remote.fallbackUrl(
      reciterId: reciterId,
      ayahNumber: _sequentialAyahNumber(surah, ayah),
      bitrate: bitrate,
    );
  }
}
