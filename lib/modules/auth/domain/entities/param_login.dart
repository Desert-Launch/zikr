import 'package:equatable/equatable.dart';

class ParamLogin extends Equatable {
  const ParamLogin({required this.identifier, required this.password});

  /// Email or phone — the backend looks both up.
  final String identifier;
  final String password;

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'password': password,
  };

  @override
  List<Object?> get props => [identifier, password];
}
