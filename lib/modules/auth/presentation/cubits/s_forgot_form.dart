import 'package:equatable/equatable.dart';

class SForgotForm extends Equatable {
  const SForgotForm({
    this.email = '',
    this.isSubmitting = false,
    this.didSend = false,
    this.error,
  });

  final String email;
  final bool isSubmitting;
  final bool didSend;
  final String? error;

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  bool get isValid => _emailRegex.hasMatch(email.trim());

  SForgotForm copyWith({
    String? email,
    bool? isSubmitting,
    bool? didSend,
    String? error,
    bool clearError = false,
  }) {
    return SForgotForm(
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      didSend: didSend ?? this.didSend,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [email, isSubmitting, didSend, error];
}
