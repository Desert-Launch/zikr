import 'package:equatable/equatable.dart';

class SRegisterForm extends Equatable {
  const SRegisterForm({
    this.name = '',
    this.birthDate = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.error,
  });

  final String name;
  final String birthDate;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final bool obscurePassword;
  final String? error;

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  bool get isNameValid => name.trim().length >= 2;
  bool get isBirthDateValid => birthDate.trim().isNotEmpty;
  bool get isEmailValid => _emailRegex.hasMatch(email.trim());
  bool get isPhoneValid => phone.replaceAll(' ', '').isNotEmpty;
  bool get isPasswordValid => _passwordRegex.hasMatch(password);
  bool get passwordsMatch => password == confirmPassword;

  bool get isValid =>
      isNameValid &&
      isBirthDateValid &&
      isEmailValid &&
      isPhoneValid &&
      isPasswordValid &&
      passwordsMatch;

  SRegisterForm copyWith({
    String? name,
    String? birthDate,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    bool? obscurePassword,
    String? error,
    bool clearError = false,
  }) {
    return SRegisterForm(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    name,
    birthDate,
    email,
    phone,
    password,
    confirmPassword,
    isSubmitting,
    obscurePassword,
    error,
  ];
}
