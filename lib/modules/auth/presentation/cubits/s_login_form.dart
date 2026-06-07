import 'package:equatable/equatable.dart';

class SLoginForm extends Equatable {
  const SLoginForm({
    this.identifier = '',
    this.password = '',
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.error,
  });

  final String identifier;
  final String password;
  final bool isSubmitting;
  final bool obscurePassword;
  final String? error;

  bool get isValid => identifier.trim().isNotEmpty && password.length >= 8;

  SLoginForm copyWith({
    String? identifier,
    String? password,
    bool? isSubmitting,
    bool? obscurePassword,
    String? error,
    bool clearError = false,
  }) {
    return SLoginForm(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    identifier,
    password,
    isSubmitting,
    obscurePassword,
    error,
  ];
}
