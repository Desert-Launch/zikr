import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/data/models/m_auth_token.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/domain/entities/param_login.dart';
import 'package:quran/modules/auth/domain/entities/param_register.dart';
import 'package:quran/modules/auth/domain/entities/param_reset.dart';

class AuthSuccess {
  const AuthSuccess({required this.user, required this.token});
  final MUser user;
  final MAuthToken token;
}

abstract class RAuth {
  Future<Either<Failure, AuthSuccess>> login(ParamLogin p);
  Future<Either<Failure, AuthSuccess>> register(ParamRegister p);
  Future<Either<Failure, Unit>> forgotPassword(String email);
  Future<Either<Failure, Unit>> verifyOtp({
    required String email,
    required String otp,
  });
  Future<Either<Failure, Unit>> resetPassword(ParamReset p);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, MUser>> currentUser();
  Future<bool> isLoggedIn();
}
