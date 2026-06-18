import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';

/// App-wide reader display settings shared by the reader and the settings
/// screen. Kept intentionally small; transient per-session state (selection,
/// chrome visibility, current page) stays in `SMushafReader`.
class SReaderSettings extends Equatable {
  const SReaderSettings({this.fontMode = EQuranFontMode.plainV1});

  final EQuranFontMode fontMode;

  SReaderSettings copyWith({EQuranFontMode? fontMode}) =>
      SReaderSettings(fontMode: fontMode ?? this.fontMode);

  @override
  List<Object?> get props => [fontMode];
}
