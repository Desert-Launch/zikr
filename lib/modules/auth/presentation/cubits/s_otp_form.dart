import 'package:equatable/equatable.dart';

class SOtpForm extends Equatable {
  const SOtpForm({
    this.otp = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.didReset = false,
    this.error,
  });

  final String otp;
  final String newPassword;
  final String confirmPassword;
  final bool isSubmitting;
  final bool obscurePassword;
  final bool didReset;
  final String? error;

  static final _passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  bool get isOtpValid => RegExp(r'^\d{6}$').hasMatch(otp);
  bool get isPasswordValid => _passwordRegex.hasMatch(newPassword);
  bool get passwordsMatch => newPassword == confirmPassword;
  bool get isValid => isOtpValid && isPasswordValid && passwordsMatch;

  SOtpForm copyWith({
    String? otp,
    String? newPassword,
    String? confirmPassword,
    bool? isSubmitting,
    bool? obscurePassword,
    bool? didReset,
    String? error,
    bool clearError = false,
  }) {
    return SOtpForm(
      otp: otp ?? this.otp,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      didReset: didReset ?? this.didReset,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [otp, newPassword, confirmPassword, isSubmitting, obscurePassword, didReset, error];
}
