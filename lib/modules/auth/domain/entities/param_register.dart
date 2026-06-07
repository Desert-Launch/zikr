import 'package:equatable/equatable.dart';

class ParamRegister extends Equatable {
  const ParamRegister({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.birthDate,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String? birthDate;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    if (birthDate != null) 'birth_date': birthDate,
  };

  @override
  List<Object?> get props => [name, email, phone, password, birthDate];
}
