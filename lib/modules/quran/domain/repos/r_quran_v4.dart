import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';

/// Reader repository for the QPC-V4 colored-tajweed Mushaf edition.
abstract class RQuranV4 {
  /// Resolves [page] (1..604) into renderable QPC-V4 blocks.
  Future<Either<Failure, MQpcV4Page>> getPage(int page);
}
