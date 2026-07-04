import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_qpc_v4_data.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/repos/r_quran_v4.dart';

class RImplQuranV4 implements RQuranV4 {
  RImplQuranV4(this._data);
  final DSQpcV4Data _data;

  @override
  Future<Either<Failure, MQpcV4Page>> getPage(int page) async {
    if (page < 1 || page > 604) {
      return Left(Failure.validationFailure(message: 'Page must be 1..604'));
    }
    try {
      return Right(await _data.loadPage(page));
    } catch (e, st) {
      ErrorHelper.printDebugError(
          name: 'RImplQuranV4.getPage', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
