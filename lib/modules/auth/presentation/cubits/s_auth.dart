import 'package:equatable/equatable.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/domain/entities/e_auth_status.dart';

class SAuth extends Equatable {
  const SAuth({this.status = EAuthStatus.unknown, this.user, this.error});

  final EAuthStatus status;
  final MUser? user;
  final String? error;

  bool get isLoggedIn => status == EAuthStatus.loggedIn && user != null;

  SAuth copyWith({
    EAuthStatus? status,
    MUser? user,
    bool clearUser = false,
    String? error,
    bool clearError = false,
  }) {
    return SAuth(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}
