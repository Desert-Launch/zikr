import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/domain/entities/param_register.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCRegister {
  UCRegister(this._repo);
  final RAuth _repo;

  Future<Either<Failure, AuthSuccess>> call(ParamRegister p) =>
      _repo.register(p);
}
