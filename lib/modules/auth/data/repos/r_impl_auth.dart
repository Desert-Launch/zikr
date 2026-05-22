import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/auth/data/datasources/remote/ds_remote_auth.dart';
import 'package:quran/modules/auth/data/models/m_auth_token.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/data/sources/local/box_auth_token.dart';
import 'package:quran/modules/auth/data/sources/local/box_user.dart';
import 'package:quran/modules/auth/domain/entities/param_login.dart';
import 'package:quran/modules/auth/domain/entities/param_register.dart';
import 'package:quran/modules/auth/domain/entities/param_reset.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class RImplAuth implements RAuth {
  RImplAuth({
    required DSRemoteAuth remote,
    required BoxUser userBox,
    required BoxAuthToken tokenBox,
  })  : _remote = remote,
        _userBox = userBox,
        _tokenBox = tokenBox;

  final DSRemoteAuth _remote;
  final BoxUser _userBox;
  final BoxAuthToken _tokenBox;

  Failure _failureFromDio(DioException e) {
    final data = e.response?.data;
    final msg = data is Map ? (data['error']?.toString() ?? e.message ?? 'Network error') : (e.message ?? 'Network error');
    final code = e.response?.statusCode;
    if (code == 401) return Failure.authenticationFailure(message: msg);
    if (code == 400 || code == 422) return Failure.validationFailure(message: msg);
    if (code == 404) return Failure.notFoundFailure(message: msg);
    if (code != null && code >= 500) {
      return Failure.serverFailure(message: msg, statusCode: code);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure.networkFailure(message: msg);
    }
    return Failure.unexpectedFailure(message: msg);
  }

  @override
  Future<Either<Failure, AuthSuccess>> login(ParamLogin p) async {
    try {
      final res = await _remote.login(identifier: p.identifier, password: p.password);
      final body = res.data ?? const {};
      final user = MUser.fromJson(body['user'] as Map<String, dynamic>);
      final token = MAuthToken(
        accessToken: body['access_token']?.toString() ?? '',
        refreshToken: body['refresh_token']?.toString() ?? '',
      );
      await _userBox.save(user);
      await _tokenBox.save(token);
      return Right(AuthSuccess(user: user, token: token));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.login', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSuccess>> register(ParamRegister p) async {
    try {
      final res = await _remote.register(
        name: p.name, email: p.email, phone: p.phone, password: p.password,
      );
      final body = res.data ?? const {};
      final user = MUser.fromJson(body['user'] as Map<String, dynamic>);
      final token = MAuthToken(
        accessToken: body['access_token']?.toString() ?? '',
        refreshToken: body['refresh_token']?.toString() ?? '',
      );
      await _userBox.save(user);
      await _tokenBox.save(token);
      return Right(AuthSuccess(user: user, token: token));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.register', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.forgotPassword', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String email, required String otp,
  }) async {
    try {
      await _remote.verifyOtp(email: email, otp: otp);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.verifyOtp', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(ParamReset p) async {
    try {
      await _remote.resetPassword(
        email: p.email, otp: p.otp, newPassword: p.newPassword,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.resetPassword', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // Best-effort server logout; still clear local state on failure.
      try { await _remote.logout(); } catch (_) {}
      await _userBox.clear();
      await _tokenBox.clear();
      return const Right(unit);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.logout', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MUser>> currentUser() async {
    final cached = _userBox.current();
    if (cached != null) return Right(cached);
    try {
      final res = await _remote.me();
      final body = res.data ?? const {};
      final user = MUser.fromJson(body['user'] as Map<String, dynamic>);
      await _userBox.save(user);
      return Right(user);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplAuth.currentUser', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _tokenBox.current();
    return token != null && token.accessToken.isNotEmpty;
  }
}
