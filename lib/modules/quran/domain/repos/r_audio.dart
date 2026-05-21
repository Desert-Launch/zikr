import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';

abstract class RAudio {
  /// Returns either a local file path (when the ayah is downloaded) or a remote URL.
  Future<Either<Failure, String>> resolveAyahAudio({
    required String reciterId,
    required int surah,
    required int ayah,
  });

  /// Returns the AlQuran.cloud fallback URL for this ayah, or null when no
  /// known mapping exists for [reciterId]. Used when the primary CDN 404s.
  String? fallbackUrlFor({
    required String reciterId,
    required int surah,
    required int ayah,
  });

  /// Resolve a contiguous range of ayat; the list is ordered (surah, ayah) ascending.
  Future<Either<Failure, List<String>>> resolveRange({
    required String reciterId,
    required int fromSurah,
    required int fromAyah,
    required int toSurah,
    required int toAyah,
  });

  /// True if the file is already on disk for the given (reciter, surah, ayah).
  Future<bool> isDownloaded({
    required String reciterId,
    required int surah,
    required int ayah,
  });
}
