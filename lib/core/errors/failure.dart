import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  // Factory constructors for common failure types
  const factory Failure.serverFailure({
    required String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.networkFailure({
    required String message,
  }) = NetworkFailure;

  const factory Failure.authenticationFailure({
    required String message,
  }) = AuthenticationFailure;

  const factory Failure.notFoundFailure({
    required String message,
  }) = NotFoundFailure;

  const factory Failure.validationFailure({
    required String message,
  }) = ValidationFailure;

  const factory Failure.cacheFailure({
    required String message,
  }) = CacheFailure;

  const factory Failure.unexpectedFailure({
    required String message,
  }) = UnexpectedFailure;
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message}) : super(statusCode: null);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message}) : super(statusCode: 401);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message}) : super(statusCode: 404);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message}) : super(statusCode: 422);
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message}) : super(statusCode: null);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message}) : super(statusCode: null);
}
