import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/domain/entities/param_reset.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCResetPassword {
  UCResetPassword(this._repo);
  final RAuth _repo;

  Future<Either<Failure, Unit>> call(ParamReset p) => _repo.resetPassword(p);
}
