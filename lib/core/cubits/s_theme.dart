import 'package:equatable/equatable.dart';

enum EThemeMode { system, light, dark }

class STheme extends Equatable {
  const STheme({this.mode = EThemeMode.system});

  final EThemeMode mode;

  STheme copyWith({EThemeMode? mode}) => STheme(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
