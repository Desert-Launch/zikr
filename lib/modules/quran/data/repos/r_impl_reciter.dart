import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_reciters.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_settings.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/domain/repos/r_reciter.dart';

class RImplReciter implements RReciter {
  RImplReciter(this._settings, this._catalog);
  final DSLocalSettings _settings;
  final DSLocalReciters _catalog;

  Future<List<MReciter>> _loadCache() => _catalog.all();

  @override
  Future<Either<Failure, List<MReciter>>> getReciters() async {
    try {
      return Right(await _loadCache());
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplReciter.getReciters', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MReciter>> getActive() async {
    try {
      final list = await _loadCache();
      final saved = _settings.getActiveReciterId();
      if (saved != null) {
        final hit = list.where((r) => r.id == saved).firstOrNull;
        if (hit != null) return Right(hit);
      }
      final def = list.where((r) => r.isDefault).firstOrNull ?? list.first;
      return Right(def);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplReciter.getActive', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActive(String reciterId) async {
    try {
      await _settings.setActiveReciterId(reciterId);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplReciter.setActive', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
