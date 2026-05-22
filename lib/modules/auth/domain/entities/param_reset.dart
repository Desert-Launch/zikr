import 'package:equatable/equatable.dart';

class ParamReset extends Equatable {
  const ParamReset({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      };

  @override
  List<Object?> get props => [email, otp, newPassword];
}
