import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCVerifyOtp {
  UCVerifyOtp(this._repo);
  final RAuth _repo;

  Future<Either<Failure, Unit>> call({required String email, required String otp}) =>
      _repo.verifyOtp(email: email, otp: otp);
}
